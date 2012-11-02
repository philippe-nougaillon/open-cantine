# encoding: utf-8

class UserMailer < ActionMailer::Base
  default :from => "contact@opencantine.net"  
  
  def registration_confirmation(user)  
    mail(:to => user.email, :subject => "Registered")  
  end  

  def send_password(famille)
	@famille = famille
	mail(:subject => 'Pour consulter votre compte', :recipients => famille.email, :sent_on => Time.now)
  end

  def send_invoice(ville, famille, facture)
	@ville = ville
	@famille = famille
	@facture = facture
    attachments["Facture #{@facture.ref}.pdf"] = File.read("#{Rails.root}/pdfs/#{facture.id}.pdf")
	mail(:subject => "#{@ville.nom} - Facture périscolaire", :to => @famille.email, :cc => @ville.email)
  end


  def send_login(username,ip)
	mail(:to => "philippe.nougaillon@gmail.com", :subject => "#{username} s'est connecté depuis : #{ip}")
  end

  def send_info(email)
	@email = email
	mail( :subject => "openCantine.net - Vos identifiants de connexion", :to => @email) 
  end
end
