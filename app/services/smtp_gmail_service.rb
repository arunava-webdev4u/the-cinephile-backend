class SmtpGmailService
    require "net/smtp"
    require "mail"

    # Custom exceptions
    class EmailError < StandardError; end
    class ConfigurationError < EmailError; end
    class DeliveryError < EmailError; end

    def initialize
        @smtp_settings = {
            address:              "smtp.gmail.com",
            port:                 465,
            domain:               "gmail.com",
            user_name:            ENV["SMTP_GMAIL_APP_USERNAME"],
            password:             ENV["SMTP_GMAIL_APP_PASSWORD"],
            authentication:       "plain",
            ssl:                  true,
            enable_starttls_auto: true
        }

        validate_configuration!
    end

    def send_welcome_email(user)
        raise EmailError, "User cannot be nil" if user.nil?
        raise EmailError, "User email is required" if user.email.blank?
        raise EmailError, "User first name is required" if user.first_name.blank?

        begin
            mail = build_welcome_email(user)
            deliver_email(mail)

            Rails.logger.info "Welcome email sent successfully to #{user.email}"
            { success: true, message: "Welcome email sent successfully" }

        rescue => e
            Rails.logger.error "Failed to send welcome email to #{user.email}: #{e.message}"
            handle_email_error(e)
        end
    end


    def send_password_reset_email!(reset_details)
        validate_configuration!

        mail = build_password_reset_email(reset_details)
        deliver_email(mail)

        Rails.logger.info "Password reset email sent successfully to #{reset_details[:email]}"
        { success: true, message: "Password reset email sent successfully" }
    end

    def send_verification_email(registration_details)
        raise EmailError, "Registration details cannot be nil" if registration_details.nil?
        raise EmailError, "Registration email is required" if registration_details[:email].nil?
        raise EmailError, "Registration otp_code is required" if registration_details[:otp_code].nil?

        begin
            mail = build_verification_email(registration_details)
            deliver_email(mail)

            Rails.logger.info "Verification email sent successfully to #{registration_details[:email]}"
            { success: true, message: "Verification email sent successfully" }

        rescue => e
            Rails.logger.error "Failed to send verification email to #{registration_details[:email]}: #{e.message}"
            handle_email_error(e)
        end
    end

    # Bang variant — raises on failure so Sidekiq can retry the job
    def send_verification_email!(registration_details)
        raise EmailError, "Registration details cannot be nil" if registration_details.nil?
        raise EmailError, "Registration email is required" if registration_details[:email].nil?
        raise EmailError, "Registration otp_code is required" if registration_details[:otp_code].nil?

        mail = build_verification_email(registration_details)
        deliver_email(mail)

        Rails.logger.info "Verification email sent successfully to #{registration_details[:email]}"
    end

    def validate_configuration!
        missing_configs = []

        missing_configs << "SMTP_GMAIL_APP_USERNAME" if ENV["SMTP_GMAIL_APP_USERNAME"].blank?
        missing_configs << "SMTP_GMAIL_APP_PASSWORD" if ENV["SMTP_GMAIL_APP_PASSWORD"].blank?

        unless missing_configs.empty?
        raise ConfigurationError, "Missing required environment variables: #{missing_configs.join(', ')}"
        end
    end

    def build_welcome_email(user)
        html_content = welcome_email_html_template(user)
        text_content = welcome_email_text_template(user)
        subject_line = "Welcome to #{app_name()}!"
        from_email = ENV["SMTP_GMAIL_APP_USERNAME"]

        mail = Mail.new do
            from     from_email
            to       user.email
            subject  subject_line

            html_part do
                content_type "text/html; charset=UTF-8"
                body html_content
            end

            text_part do
                body text_content
            end
        end

        configure_mail_delivery(mail)
        mail
    end

    def build_verification_email(registration_details)
        html_content = verification_email_html_template(registration_details)
        text_content = verification_email_text_template(registration_details)
        subject_line = "Verify email for #{app_name()}!"
        from_email = ENV["SMTP_GMAIL_APP_USERNAME"]

        mail = Mail.new do
            from     from_email
            to       registration_details[:email]
            subject  subject_line

            html_part do
                content_type "text/html; charset=UTF-8"
                body html_content
            end

            text_part do
                body text_content
            end
        end

        configure_mail_delivery(mail)
        mail
    end

    def build_password_reset_email(reset_details)
        html_content = password_reset_html_template(reset_details)
        text_content = password_reset_text_template(reset_details)
        subject_line = "Reset your password - #{app_name()}"
        from_email = ENV["SMTP_GMAIL_APP_USERNAME"]

        mail = Mail.new do
            from     from_email
            to       reset_details[:email]
            subject  subject_line

            html_part do
                content_type "text/html; charset=UTF-8"
                body html_content
            end

            text_part do
                body text_content
            end
        end

        configure_mail_delivery(mail)
        mail
    end

    def configure_mail_delivery(mail)
        mail.delivery_method :smtp, @smtp_settings
    end

    def deliver_email(mail)
        mail.deliver!
    rescue Net::SMTPAuthenticationError => e
        raise DeliveryError, "SMTP authentication failed. Please check your Gmail credentials and ensure you're using an App Password."
    rescue Net::SMTPServerBusy => e
        raise DeliveryError, "SMTP server is busy. Please try again later."
    rescue Net::SMTPSyntaxError => e
        raise DeliveryError, "Invalid email format or SMTP syntax error."
    rescue Net::SMTPFatalError => e
        raise DeliveryError, "Fatal SMTP error: #{e.message}"
    rescue => e
        raise DeliveryError, "Failed to deliver email: #{e.message}"
    end

    def handle_email_error(error)
        case error
        when ConfigurationError, DeliveryError
            { success: false, error: error.class.name, message: error.message }
        else
            { success: false, error: "EmailError", message: "An unexpected error occurred while sending email" }
        end
    end

    # Email Templates
    def welcome_email_html_template(user)
        app_name_var = app_name
        app_link_var = app_link
        current_year = Date.current.year

        <<~HTML
        <!DOCTYPE html>
        <html>
            <head>
                <meta charset="UTF-8">
                <title>Welcome to #{app_name}</title>

                <style>
                    body {
                        font-family: Arial, sans-serif;
                        line-height: 1.6;
                        color: #333;
                    }
                    .container {
                        max-width: 600px;
                        margin: 0 auto;
                        padding: 20px;
                    }
                    .header {#{' '}
                        background-image: url('https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D');
                        background-size: cover;
                        background-position: center;
                        color: white;#{' '}
                        padding: 40px 20px;#{' '}
                        text-align: center;
                    }
                    .content {
                        padding: 20px; background-color: #f9f9f9;
                    }
                    .button {
                        display: inline-block;
                        padding: 10px 20px;
                        background-color: #4CAF50;
                        color: white;
                        text-decoration: none;
                        border-radius: 5px;
                    }
                    .footer {
                        margin-top: 20px;
                        padding: 10px;
                        font-size: 12px;
                        color: #666;
                        text-align: center;
                    }
                    .button-container {
                        display: flex;
                        justify-content: center;
                    }
                    h2 {
                        text-align: center;
                    }
                </style>
            </head>

            <body>
                <div class="container">
                    <div class="header">
                        <h1>Welcome to #{app_name}!</h1>
                    </div>
                    <div class="content">
                        <h2>Hello #{user.first_name}!</h2>
                        <p>Thank you for signing up with #{app_name}. We're excited to have you on board!</p>
                        <p>You can now start exploring our features and make the most out of your experience.</p>
                        <p class="button-container">
                            <a href="#{app_link}" class="button">Get Started</a>
                        </p>
                    </div>
                    <div class="footer">
                        <p>© #{Date.current.year} #{app_name}. All rights reserved.</p>
                        <p>If you didn't create an account with us, please ignore this email.</p>
                    </div>
                </div>
            </body>
        </html>
        HTML
    end

    def welcome_email_text_template(user)
        <<~TEXT
        Welcome to #{app_name}!

        Hello #{user.first_name}!

        Thank you for signing up with #{app_name}. We're excited to have you on board!

        You can now start exploring our features and make the most out of your experience.

        Get started: #{app_link}

        © #{Date.current.year} #{app_name}. All rights reserved.
        If you didn't create an account with us, please ignore this email.
        TEXT
    end

    def verification_email_html_template(registration_details)
        <<~HTML
        <!DOCTYPE html>
        <html>
            <head>
            <meta charset="UTF-8">
            <title>Verify Your Email - #{app_name}</title>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background-color: #2196F3; color: white; padding: 20px; text-align: center; }
                .content { padding: 20px; background-color: #f9f9f9; }
                .button { display: inline-block; padding: 10px 20px; background-color: #2196F3; color: white; text-decoration: none; border-radius: 5px; }
                .footer { margin-top: 20px; padding: 10px; font-size: 12px; color: #666; text-align: center; }
            </style>
            </head>
            <body>
            <div class="container">
                <div class="header">
                    <h1>Verify Your Email</h1>
                </div>
                <div class="content">
                    <h2>Hello #{registration_details[:first_name]}!</h2>
                    <p>Thank you for signing up with #{app_name}. To complete your registration, please verify your email address.</p>
                    <p>This is your OTP: #{registration_details[:otp_code]}</p>
                    <p>If you didn't create an account with us, please ignore this email.</p>
                </div>
                <div class="footer">
                    <p>© #{Date.current.year} #{app_name}. All rights reserved.</p>
                </div>
            </div>
            </body>
        </html>
        HTML
    end

    def verification_email_text_template(registration_details)
        <<~TEXT
        Verify Your Email - #{app_name}

        Hello #{registration_details[:first_name]}!

        Thank you for signing up with #{app_name}. To complete your registration, please verify your email address.

        This is your OTP: #{registration_details[:otp_code]}

        If you didn't create an account with us, please ignore this email.

        © #{Date.current.year} #{app_name}. All rights reserved.
        TEXT
    end

    def password_reset_html_template(reset_details)
        <<~HTML
        <!DOCTYPE html>
        <html>
            <body style="font-family: Arial, sans-serif; margin: 0; padding: 20px;">
            <h2>Reset Your Password</h2>
            <p>Hello #{reset_details[:first_name]}!</p>
            <p>We received a request to reset your password. Use the code below to proceed:</p>
            <p style="font-size: 24px; font-weight: bold; letter-spacing: 4px;">#{reset_details[:otp_code]}</p>
            <p>This code expires in 10 minutes.</p>
            <p>© #{Date.current.year} #{app_name}. All rights reserved.</p>
            </body>
        </html>
        HTML
    end

    def password_reset_text_template(reset_details)
        <<~TEXT
        Reset Your Password - #{app_name}

        Hello #{reset_details[:first_name]}!

        We received a request to reset your password. Use the code below to proceed:

        This is your OTP: #{reset_details[:otp_code]}

        This code expires in 10 minutes.

        © #{Date.current.year} #{app_name}. All rights reserved.
        TEXT
    end

    # Helper methods
    def app_name
        ENV["APP_NAME"] || "The Cinephile"
    end

    def app_link
        ENV["APP_LINK"] || "https://the-cinephile-frontend.vercel.app/"
    end
end
