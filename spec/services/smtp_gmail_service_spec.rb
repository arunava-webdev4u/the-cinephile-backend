require 'rails_helper'

RSpec.describe SmtpGmailService, type: :service do
    before do
        allow(ENV).to receive(:[]).with("SMTP_GMAIL_APP_USERNAME").and_return("testuser@gmail.com")
        allow(ENV).to receive(:[]).with("SMTP_GMAIL_APP_PASSWORD").and_return("password")
        allow(ENV).to receive(:[]).with("APP_NAME").and_return("The Cinephile")
        allow(ENV).to receive(:[]).with("APP_LINK").and_return("https://the-cinephile-frontend.vercel.app/")
    end

    context "configuration validation" do
        it "raises ConfigurationError when username is missing" do
            allow(ENV).to receive(:[]).with("SMTP_GMAIL_APP_USERNAME").and_return(nil)
            expect { described_class.new }.to raise_error(SmtpGmailService::ConfigurationError)
        end

        it "raises ConfigurationError when password is missing" do
            allow(ENV).to receive(:[]).with("SMTP_GMAIL_APP_PASSWORD").and_return(nil)
            expect { described_class.new }.to raise_error(SmtpGmailService::ConfigurationError)
        end

        it "does not raise error when config is valid" do
            expect { described_class.new }.not_to raise_error
        end
    end


    context "validation" do
        let(:service) { described_class.new }
        let(:registration_details) { { email: user.email, first_name: user.first_name, last_name: user.last_name, otp_code: "123456" } }

        describe "#send_welcome_email" do
            it "raises error if user is nil" do
                expect { service.send_welcome_email(nil) }.to raise_error(SmtpGmailService::EmailError, "User cannot be nil")
            end

            it "raises error if email is blank" do
                user = create(:user)
                user[:email] = nil

                expect { service.send_welcome_email(user) }.to raise_error(SmtpGmailService::EmailError, "User email is required")
            end
        end

        it "raises error if first_name is blank" do
            user = create(:user)
            user[:first_name] = nil

            expect { service.send_welcome_email(user) }.to raise_error(SmtpGmailService::EmailError, "User first name is required")
        end

        describe "#send_verification_email" do
            it "raises error if details are nil" do
                expect { service.send_verification_email(nil) }.to raise_error(SmtpGmailService::EmailError, "Registration details cannot be nil")
            end

            it "raises error if email is blank" do
                registration_details = { email: nil, first_name: "Test", last_name: "User", otp_code: "123456" }
                expect { service.send_verification_email(registration_details) }.to raise_error(SmtpGmailService::EmailError, "Registration email is required")
            end

            it "raises error if otp_code is blank" do
                registration_details = { email: "test_user@gmail.com", first_name: "Test", last_name: "User", otp_code: nil }
                expect { service.send_verification_email(registration_details) }.to raise_error(SmtpGmailService::EmailError, "Registration otp_code is required")
            end
        end
    end

    context "email delivery" do
        let(:service) { described_class.new }
        let(:user) { double(email: "user@example.com", first_name: "Test", last_name: "User") }

        describe "#send_welcome_email" do
            it "sends welcome email successfully" do
                mail_double = instance_double("Fake Delivery", deliver!: true)
                allow(service).to receive(:build_welcome_email).and_return(mail_double)

                result = service.send_welcome_email(user)
                expect(result).to eq({ success: true, message: "Welcome email sent successfully" })
            end

            it "handles email sending failure" do
                mail_double = double("Mail")
                allow(service).to receive(:build_welcome_email).with(user).and_return(mail_double)
                allow(service).to receive(:deliver_email).with(mail_double).and_raise(SmtpGmailService::DeliveryError)
                allow(service).to receive(:handle_email_error).with(instance_of(SmtpGmailService::DeliveryError)).and_return({ success: false, message: "Failed to send welcome email" })

                result = service.send_welcome_email(user)

                expect(result[:success]).to be false
                expect(result[:message]).to eq("Failed to send welcome email")
            end
        end

        describe "#send_verification_email" do
            it "sends verification email successfully" do
                registration_details = { email: "test_user@gmail.com", first_name: "Test", last_name: "User", otp_code: "123456" }
                mail_double = instance_double("Fake Delivery", deliver!: true)
                allow(service).to receive(:build_verification_email).and_return(mail_double)

                result = service.send_verification_email(registration_details)
                expect(result).to eq({ success: true, message: "Verification email sent successfully" })
            end

            it "handles email sending failure" do
                mail_double = double("Mail")
                registration_details = { email: "test_user@gmail.com", first_name: "Test", last_name: "User", otp_code: "123456" }

                allow(service).to receive(:build_verification_email).with(registration_details).and_return(mail_double)
                allow(service).to receive(:deliver_email).with(mail_double).and_raise(SmtpGmailService::DeliveryError)
                allow(service).to receive(:handle_email_error).with(instance_of(SmtpGmailService::DeliveryError)).and_return({ success: false, message: "Failed to send verification email" })

                result = service.send_verification_email(registration_details)
                expect(result[:success]).to be false
                expect(result[:message]).to eq("Failed to send verification email")
            end
        end
    end

    context "building email contents" do
        let(:service) { described_class.new }
        let(:user) { double(email: "user@example.com", first_name: "Test", last_name: "User") }
        let(:registration_details) { { email: user.email, first_name: user.first_name, last_name: user.last_name, otp_code: "123456" } }

        describe "#welcome_email_html_template" do
            it "renders user's first name and app name" do
                html = service.welcome_email_html_template(user)
                assert_includes html, "#{user.first_name}"
                assert_includes html, Date.current.year.to_s
                assert_includes html, "<!DOCTYPE html>"
                assert_includes html, "Welcome to #{ENV["APP_NAME"]}!"
            end
        end

        describe "#welcome_email_text_template" do
            it "renders user's first name and app name" do
                text = service.welcome_email_html_template(user)
                assert_includes text, "#{user.first_name}"
                assert_includes text, Date.current.year.to_s
                assert_includes text, "Welcome to #{ENV["APP_NAME"]}!"
            end
        end

        describe "#verification_email_html_template" do
            it "renders otp code" do
                html = service.verification_email_html_template(registration_details)
                assert_includes html, "This is your OTP: #{registration_details[:otp_code]}"
            end
        end

        describe "#verification_email_text_template" do
            it "renders otp code" do
                text = service.verification_email_html_template(registration_details)
                assert_includes text, "This is your OTP: #{registration_details[:otp_code]}"
            end
        end

        describe "#build_welcome_email" do
            it "builds the email with proper subject, from, to" do
                result = service.build_welcome_email(user)

                expect(result.subject).to eq("Welcome to #{ENV['APP_NAME']}!")
                expect(result.to).to eq([ user.email ])
                expect(result.from).to eq([ ENV["SMTP_GMAIL_APP_USERNAME"] ])
            end

            it "builds the email with html & text content" do
                result = service.build_welcome_email(user)

                assert_includes result.html_part.body, "<!DOCTYPE html>"
                assert_includes result.html_part.body, "Welcome to #{ENV['APP_NAME']}!"
                assert_includes result.html_part.body, "Hello #{user.first_name}!"

                assert_includes result.text_part.body, "Welcome to #{ENV['APP_NAME']}!"
                assert_includes result.text_part.body, "Hello #{user.first_name}!"
            end
        end

        describe "#build_verification_email" do
            it "builds the email with proper subject, from, to" do
                result = service.build_verification_email(registration_details)

                expect(result.subject).to eq("Verify email for #{ENV['APP_NAME']}!")
                expect(result.from).to eq([ ENV["SMTP_GMAIL_APP_USERNAME"] ])
                expect(result.to).to eq([ registration_details[:email] ])
            end

            it "builds the email with html & text content" do
                result = service.build_verification_email(registration_details)

                assert_includes result.html_part.body, "<!DOCTYPE html>"
                assert_includes result.html_part.body, "Verify Your Email - #{ENV['APP_NAME']}"
                assert_includes result.html_part.body, "OTP: #{registration_details[:otp_code]}"

                assert_includes result.text_part.body, "Verify Your Email - #{ENV['APP_NAME']}"
                assert_includes result.text_part.body, "OTP: #{registration_details[:otp_code]}"
            end
        end
    end
end
