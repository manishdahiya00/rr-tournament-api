class UserMailer < ApplicationMailer
  default from: "rrofficial2025@gmail.com"

  def otp_email(user, otp)
    @user = user
    mail(to: @user.email, subject: "OTP for RR Tournament is #{otp}")
  end
end
