# -*- encoding: utf-8 -*-
require 'smtp_password_encryptor'

class NoticeMailer < ActionMailer::Base
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.notice_mailer.sendmail_confirm.subject
  #

  # test送信用メソッド
  def sendmail_confirm(mail_sender, destination)
    @greeting="hi!"

    old_settings = ActionMailer::Base.smtp_settings
    begin
      NoticeMailer.setup(mail_sender)
      (mail from: "noticemailer_test@aaa.com", to: destination).deliver
    ensure
      ActionMailer::Base.smtp_settings = old_settings
    end
  end

  # mail配信メソッド
  def NoticeMailer.send_mail(mail_sender, destination, cc, bcc, from, subject, body, attachment_files, in_reply_to=nil)
    old_settings = ActionMailer::Base.smtp_settings
    begin
      NoticeMailer.setup(mail_sender)
      current_mail = create_mail(ActionMailer::Base.smtp_settings[:domain], destination, cc, bcc, from, subject, body, attachment_files, in_reply_to)
      yield(current_mail) if block_given?
      current_mail.deliver
    ensure
      ActionMailer::Base.smtp_settings = old_settings
    end
  end

  def create_mail(domain, destination, cc, bcc, from, subject, body, attachment_files, in_reply_to=nil)
    headers['Message-ID'] = "#{SecureRandom.uuid}@#{domain}"
    headers["In-Reply-To"] = in_reply_to if in_reply_to

    # Return-path の設定
    return_path = SysConfig.get_delivery_mails_return_path
    if return_path
      headers[:return_path] = return_path
    else
      logger.warn '"Return-Path"が設定されていません。'
    end

    attachment_files.each do |file|
      attachments[file.file_name] = file.read_file
    end

    mail( to: destination,
          cc: cc,
          bcc: bcc,
          from: from,
          subject: subject,
          body: body )
  end

private
  def NoticeMailer.setup(mail_sender)
    ActionMailer::Base.smtp_settings = {
      :enable_starttls_auto => mail_sender.smtp_settings_enable_starttls_auto?,
      :address => mail_sender.smtp_settings_address,
      :port => mail_sender.smtp_settings_port,
      :domain => mail_sender.smtp_settings_domain,
      :authentication => mail_sender.smtp_settings_authentication,
      :user_name => mail_sender.smtp_settings_user_name,
      :password => SmtpPasswordEncryptor.decrypt(mail_sender.smtp_settings_password)
    }
  end
end
