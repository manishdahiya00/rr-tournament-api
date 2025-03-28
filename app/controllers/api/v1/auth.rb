require "net/smtp"

module Api
  module V1
    class Auth < Grape::API
      include Api::V1::Defaults

      helpers do
        def send_otp(email, otp)
          return { status: 500, message: "Invalid Email" } if email.blank?

          begin
            smtp = Net::SMTP.new("smtp.gmail.com", 587)
            smtp.enable_starttls
            smtp.start("gmail.com", "rrofficial2025@gmail.com", "zcnr hjbg qtxj jewr", :login) do |smtp|
              message = <<~MESSAGE
                From: rrofficial2025@gmail.com
                To: #{email}
                Subject: OTP for RR Tournament

                Your OTP code is: #{otp}
              MESSAGE

              smtp.send_message message, "rrofficial2025@gmail.com", email
            end
          rescue StandardError => e
            Rails.logger.info "API Exception-#{Time.now}-send-otp-Error-#{e}"
            return { status: 500, message: "Failed to send OTP" }
          end

          { status: 200, message: "OTP Sent Successfully" }
        end
      end

      resource :auth do
        before { api_params }

        params do
          requires :email, type: String, allow_blank: false
          optional :referralCode, type: String, allow_blank: true
          requires :versionName, type: String, allow_blank: false
          requires :versionCode, type: String, allow_blank: false
        end

        post do
          email = params[:email].strip.downcase
          return { status: 500, message: "Invalid Email" } if email.blank?

          referral_user = nil
          if params[:referralCode].present?
            referral_user = User.find_by(refer_code: params[:referralCode])

            if referral_user.nil?
              return { status: 500, message: "Invalid referral code" }
            elsif referral_user.email == email
              return { status: 500, message: "You cannot use your own referral code" }
            end
          end

          otp = SecureRandom.random_number(10 ** 6).to_s.rjust(6, "0")
          user = User.find_or_initialize_by(email: email)

          return { status: 401, message: "Your account is banned. Please contact support." } if user.is_banned?

          otp_response = send_otp(email, otp)
          return otp_response if otp_response[:status] != 200

          begin
            user.update!(
              otp: otp,
              security_token: user.security_token || SecureRandom.uuid,
              wallet_balance: user.wallet_balance || AppConfig.first.signup_bonus,
              source_ip: user.source_ip || request.ip,
              version_name: params[:versionName],
              version_code: params[:versionCode],
              refer_code: user.refer_code || SecureRandom.hex(4),
              referral_code: referral_user&.refer_code || nil,
            )
            if !referral_user.nil?
              referral_user.update(wallet_balance: referral_user.wallet_balance + AppConfig.first.refer_bonus)
            end
            otp_response.merge(userId: user.id, securityToken: user.security_token, referCode: user.refer_code)
          rescue StandardError => e
            Rails.logger.info "API Exception-#{Time.now}-auth-#{params.inspect}-Error-#{e}"
            { status: 500, message: "Server under maintenance" }
          end
        end
      end

      resource :verifyOtp do
        before { api_params }

        params do
          requires :otp, type: String, allow_blank: false
          requires :email, type: String, allow_blank: false
        end

        post do
          user = User.find_by(email: params[:email])
          return { status: 500, message: "User not found" } unless user

          if user.otp == params[:otp]
            user.update!(otp: "")

            app_config = AppConfig.first
            {
              status: 200,
              message: "Signed In Successfully",
              userId: user.id,
              securityToken: user.security_token,
              walletBalance: user.wallet_balance,
              email: user.email,
              tel1: app_config.tel1,
              tel2: app_config.tel2,
              referCode: user.refer_code,
              minDeposit: app_config.min_deposit,
            }
          else
            { status: 500, message: "Invalid OTP" }
          end
        rescue StandardError => e
          Rails.logger.info "API Exception-#{Time.now}-verifyOtp-#{params.inspect}-Error-#{e}"
          { status: 500, message: "Server under maintenance" }
        end
      end

      resource :appOpen do
        before { api_params }

        params do
          use :common_params
        end

        post do
          user = valid_user(params[:userId], params[:securityToken])
          return { status: 500, message: "Invalid Session" } unless user
          return { status: 401, message: "You are banned. Please contact support." } if user.is_banned?

          begin
            app_config = AppConfig.first
            {
              status: 200,
              message: "Success",
              walletBalance: user.wallet_balance,
              email: user.email,
              tel1: app_config.tel1,
              tel2: app_config.tel2,
              referCode: user.refer_code,
              version: app_config.version,
              updateUrl: app_config.update_url,
              minDeposit: app_config.min_deposit,
            }
          rescue StandardError => e
            Rails.logger.info "API Exception-#{Time.now}-appOpen-#{params.inspect}-Error-#{e}"
            { status: 500, message: "Server under maintenance" }
          end
        end
      end
    end
  end
end
