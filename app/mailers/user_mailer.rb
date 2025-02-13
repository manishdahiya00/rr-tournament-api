class UserMailer < ApplicationMailer
  default from: "rrofficial2025@gmail.com"

  def otp_email(email, otp)
    @email = email
    @otp = otp
    mail(to: email, subject: "OTP for RR Tournament")
  end
end
