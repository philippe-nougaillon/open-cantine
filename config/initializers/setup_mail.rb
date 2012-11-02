ActionMailer::Base.smtp_settings = {  
  :address              => "mail.gandi.net",  
  :port                 => 587,  
  :domain               => "opencantine.net",  
  :user_name            => "nepasrepondre@opencantine.net",  
  :password             => "nepasrepondre",  
  :authentication       => "plain",  
  :enable_starttls_auto => true  
}
