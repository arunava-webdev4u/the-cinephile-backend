require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe SendVerificationEmailWorker, type: :worker do
  include ActiveSupport::Testing::TimeHelpers

  describe 'Sidekiq configuration' do
    it 'is configured with the correct queue' do
      expect(described_class.sidekiq_options['queue']).to eq(:mailers)
    end

    it 'has retry configured to 3' do
      expect(described_class.sidekiq_options['retry']).to eq(3)
    end

    it 'includes Sidekiq::Worker' do
      expect(described_class.included_modules).to include(Sidekiq::Worker)
    end
  end

  describe '#perform' do
    let(:user) { create(:user) }
    let(:verification) { create(:user_verification, user: user) }
    let(:worker) { described_class.new }

    before do
      # Ensure user has verification record
      user.verification = verification
      user.save!

      # Mock environment variables for SmtpGmailService
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('SMTP_GMAIL_APP_USERNAME').and_return('test@gmail.com')
      allow(ENV).to receive(:[]).with('SMTP_GMAIL_APP_PASSWORD').and_return('password123')
      allow(ENV).to receive(:[]).with('APP_NAME').and_return('The Cinephile')
      allow(ENV).to receive(:[]).with('APP_LINK').and_return('https://example.com')

      # Mock the email sending
      allow_any_instance_of(SmtpGmailService).to receive(:send_verification_email!)
    end

    context 'successful email sending' do
      it 'performs the job successfully' do
        expect {
          worker.perform(user.id)
        }.not_to raise_error
      end

      it 'fetches the correct user from database' do
        expect(User).to receive(:find).with(user.id).and_return(user)
        worker.perform(user.id)
      end

      it 'calls SmtpGmailService with correct registration details' do
        service_double = instance_double(SmtpGmailService)
        allow(SmtpGmailService).to receive(:new).and_return(service_double)

        expected_details = {
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          otp_code: verification.otp_code
        }

        expect(service_double).to receive(:send_verification_email!).with(expected_details)
        worker.perform(user.id)
      end

      it 'sends correct user information in the email' do
        service_spy = spy(SmtpGmailService)
        allow(SmtpGmailService).to receive(:new).and_return(service_spy)

        worker.perform(user.id)

        expect(service_spy).to have_received(:send_verification_email!).with(
          hash_including(
            email: user.email,
            first_name: user.first_name,
            last_name: user.last_name
          )
        )
      end

      it 'includes the correct OTP code in the email' do
        service_spy = spy(SmtpGmailService)
        allow(SmtpGmailService).to receive(:new).and_return(service_spy)

        worker.perform(user.id)

        expect(service_spy).to have_received(:send_verification_email!).with(
          hash_including(otp_code: verification.otp_code)
        )
      end
    end

    context 'error handling - non-retryable errors' do
      it 'catches ActiveRecord::RecordNotFound and does not retry' do
        expect(User).to receive(:find).with(999).and_raise(ActiveRecord::RecordNotFound)
        allow(Rails.logger).to receive(:error)

        # Should not raise - error is caught and logged
        expect {
          worker.perform(999)
        }.not_to raise_error
      end

      it 'logs error when user not found' do
        expect(User).to receive(:find).with(999).and_raise(ActiveRecord::RecordNotFound)

        expect(Rails.logger).to receive(:error) do |message|
          expect(message).to include('[SendVerificationEmailWorker]')
          expect(message).to include('Non-retryable failure')
          expect(message).to include('user_id=999')
        end

        worker.perform(999)
      end

      it 'catches SmtpGmailService::ConfigurationError and does not retry' do
        allow(User).to receive(:find).and_return(user)
        allow_any_instance_of(SmtpGmailService).to receive(:send_verification_email!).and_raise(
          SmtpGmailService::ConfigurationError, 'SMTP credentials are missing'
        )

        expect(Rails.logger).to receive(:error) do |message|
          expect(message).to include('[SendVerificationEmailWorker]')
          expect(message).to include('Non-retryable failure')
          expect(message).to include('ConfigurationError')
        end

        # Should not raise - error is caught and logged
        expect {
          worker.perform(user.id)
        }.not_to raise_error
      end

      it 'catches SmtpGmailService::EmailError and does not retry' do
        allow(User).to receive(:find).and_return(user)
        allow_any_instance_of(SmtpGmailService).to receive(:send_verification_email!).and_raise(
          SmtpGmailService::EmailError, 'Email is blank'
        )

        expect(Rails.logger).to receive(:error) do |message|
          expect(message).to include('[SendVerificationEmailWorker]')
          expect(message).to include('Non-retryable failure')
          expect(message).to include('EmailError')
        end

        # Should not raise - error is caught and logged
        expect {
          worker.perform(user.id)
        }.not_to raise_error
      end

      it 'logs the error message for debugging' do
        expect(User).to receive(:find).and_return(user)
        error_msg = 'Test error message'
        allow_any_instance_of(SmtpGmailService).to receive(:send_verification_email!).and_raise(
          SmtpGmailService::EmailError, error_msg
        )

        expect(Rails.logger).to receive(:error) do |message|
          expect(message).to include(error_msg)
        end

        worker.perform(user.id)
      end
    end

    context 'error handling - retryable errors' do
      it 'allows other StandardError types to propagate and be retried' do
        allow(User).to receive(:find).and_return(user)
        allow_any_instance_of(SmtpGmailService).to receive(:send_verification_email!).and_raise(
          StandardError, 'Network timeout'
        )

        # Retryable errors should propagate (not caught by the rescue block)
        expect {
          worker.perform(user.id)
        }.to raise_error(StandardError, 'Network timeout')
      end

      it 'allows Timeout errors to propagate for retry' do
        allow(User).to receive(:find).and_return(user)
        allow_any_instance_of(SmtpGmailService).to receive(:send_verification_email!).and_raise(Timeout::Error)

        # Should raise and let Sidekiq retry
        expect {
          worker.perform(user.id)
        }.to raise_error(Timeout::Error)
      end

      it 'allows SMTP connection errors to propagate for retry' do
        allow(User).to receive(:find).and_return(user)
        allow_any_instance_of(SmtpGmailService).to receive(:send_verification_email!).and_raise(
          Net::SMTPServerBusy, 'Server temporarily unavailable'
        )

        expect {
          worker.perform(user.id)
        }.to raise_error(Net::SMTPServerBusy)
      end

      it 'allows SMTP authentication errors to propagate for retry' do
        allow(User).to receive(:find).and_return(user)
        allow_any_instance_of(SmtpGmailService).to receive(:send_verification_email!).and_raise(
          Net::SMTPAuthenticationError, 'Authentication failed'
        )

        expect {
          worker.perform(user.id)
        }.to raise_error(Net::SMTPAuthenticationError)
      end
    end

    context 'user verification association' do
      it 'retrieves the user verification record' do
        service_spy = spy(SmtpGmailService)
        allow(SmtpGmailService).to receive(:new).and_return(service_spy)

        worker.perform(user.id)

        # Verify that the OTP code was passed (which means verification was fetched)
        expect(service_spy).to have_received(:send_verification_email!).with(
          hash_including(otp_code: an_instance_of(String))
        )
      end

      it 'uses the correct OTP from the user verification' do
        service_spy = spy(SmtpGmailService)
        allow(SmtpGmailService).to receive(:new).and_return(service_spy)

        expected_otp = verification.otp_code
        worker.perform(user.id)

        expect(service_spy).to have_received(:send_verification_email!).with(
          hash_including(otp_code: expected_otp)
        )
      end
    end
  end

  describe 'job enqueueing' do
    let(:user) { create(:user) }

    context 'with Sidekiq testing mode' do
      before do
        Sidekiq::Testing.fake!
      end

      after do
        Sidekiq::Testing.fake!
        Sidekiq::Worker.clear_all
      end

      it 'can be enqueued with user_id' do
        expect {
          described_class.perform_async(user.id)
        }.to change(described_class.jobs, :size).by(1)
      end

      it 'enqueues with the correct user_id' do
        described_class.perform_async(user.id)

        job = described_class.jobs.first
        expect(job['args']).to eq([ user.id ])
      end

      it 'enqueues multiple jobs for multiple users' do
        user2 = create(:user)

        described_class.perform_async(user.id)
        described_class.perform_async(user2.id)

        expect(described_class.jobs.size).to eq(2)
        expect(described_class.jobs[0]['args']).to eq([ user.id ])
        expect(described_class.jobs[1]['args']).to eq([ user2.id ])
      end

      it 'job is placed in the mailers queue' do
        described_class.perform_async(user.id)

        job = described_class.jobs.first
        expect(job['queue']).to eq('mailers')
      end

      it 'executes the job when explicitly called with drain' do
        create(:user_verification, user: user)
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('SMTP_GMAIL_APP_USERNAME').and_return('test@gmail.com')
        allow(ENV).to receive(:[]).with('SMTP_GMAIL_APP_PASSWORD').and_return('password123')
        allow(ENV).to receive(:[]).with('APP_NAME').and_return('The Cinephile')
        allow(ENV).to receive(:[]).with('APP_LINK').and_return('https://example.com')
        allow_any_instance_of(SmtpGmailService).to receive(:send_verification_email!)

        described_class.perform_async(user.id)

        expect {
          described_class.drain
        }.not_to raise_error
      end
    end

    context 'with Sidekiq inline mode' do
      before do
        Sidekiq::Testing.inline!
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('SMTP_GMAIL_APP_USERNAME').and_return('test@gmail.com')
        allow(ENV).to receive(:[]).with('SMTP_GMAIL_APP_PASSWORD').and_return('password123')
        allow(ENV).to receive(:[]).with('APP_NAME').and_return('The Cinephile')
        allow(ENV).to receive(:[]).with('APP_LINK').and_return('https://example.com')
      end

      after do
        Sidekiq::Testing.fake!
      end

      it 'executes the job immediately in inline mode' do
        create(:user_verification, user: user)
        service_spy = spy(SmtpGmailService)
        allow(SmtpGmailService).to receive(:new).and_return(service_spy)

        described_class.perform_async(user.id)

        expect(service_spy).to have_received(:send_verification_email!)
      end
    end
  end

  describe 'integration with real Sidekiq' do
    let(:user) { create(:user) }
    let(:verification) { create(:user_verification, user: user) }

    before do
      user.verification = verification
      user.save!
    end

    it 'responds to Sidekiq async methods' do
      expect(described_class).to respond_to(:perform_async)
      expect(described_class).to respond_to(:perform_in)
      expect(described_class).to respond_to(:perform_at)
    end

    it 'has the correct worker class name' do
      expect(described_class.name).to eq('SendVerificationEmailWorker')
    end

    it 'is a proper Sidekiq Worker' do
      expect(described_class < Sidekiq::Worker).to be_truthy
    end
  end

  describe 'edge cases' do
    let(:user) { create(:user) }
    let(:verification) { create(:user_verification, user: user) }
    let(:worker) { described_class.new }

    before do
      user.verification = verification
      user.save!

      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('SMTP_GMAIL_APP_USERNAME').and_return('test@gmail.com')
      allow(ENV).to receive(:[]).with('SMTP_GMAIL_APP_PASSWORD').and_return('password123')
      allow(ENV).to receive(:[]).with('APP_NAME').and_return('The Cinephile')
      allow(ENV).to receive(:[]).with('APP_LINK').and_return('https://example.com')
      allow_any_instance_of(SmtpGmailService).to receive(:send_verification_email!)
    end

    it 'handles user with special characters in name' do
      user.update(first_name: "José", last_name: "García")

      expect {
        worker.perform(user.id)
      }.not_to raise_error
    end

    it 'handles very long email addresses' do
      user.update(email: "#{'a' * 64}@example.com")

      expect {
        worker.perform(user.id)
      }.not_to raise_error
    end

    it 'handles expired OTP codes' do
      travel_to 11.minutes.from_now do
        verification.update(otp_expires_at: 10.minutes.ago)

        expect {
          worker.perform(user.id)
        }.not_to raise_error
      end
    end

    it 'handles verified users' do
      verification.update(verified_at: Time.current)

      # Worker should still send email even if user is already verified
      expect {
        worker.perform(user.id)
      }.not_to raise_error
    end
  end

  describe 'performance and concurrency' do
    let(:users) { create_list(:user, 5) }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('SMTP_GMAIL_APP_USERNAME').and_return('test@gmail.com')
      allow(ENV).to receive(:[]).with('SMTP_GMAIL_APP_PASSWORD').and_return('password123')
      allow(ENV).to receive(:[]).with('APP_NAME').and_return('The Cinephile')
      allow(ENV).to receive(:[]).with('APP_LINK').and_return('https://example.com')
      allow_any_instance_of(SmtpGmailService).to receive(:send_verification_email!)

      users.each do |user|
        create(:user_verification, user: user)
      end
    end

    it 'can handle multiple concurrent job executions' do
      workers = users.map { described_class.new }
      threads = workers.each_with_index.map do |worker, idx|
        Thread.new { worker.perform(users[idx].id) }
      end

      expect {
        threads.each(&:join)
      }.not_to raise_error
    end
  end
end
