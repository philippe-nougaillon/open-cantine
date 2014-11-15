# encoding: utf-8

class UserMailer < ActionMailer::Base
  default from:"nepasrepondre@opencantine.net"  
  
  def registration_confirmation(user)  
     mail(subject:"Registered", to:user.email )  
  end  

  def send_password(famille)
	   @famille = famille
	   mail(subject:'Demande de mot de passe', to:@famille.email)
  end

  def send_invoice(ville, famille, facture)
	   @ville = ville
	   @famille = famille
	   @facture = facture
     attachments["Facture #{@facture.ref}.pdf"] = File.read("#{Rails.root}/pdfs/#{facture.id}.pdf")
	   mail(subject:"#{@ville.nom} - Facture périscolaire", to:@famille.email, cc:@ville.email)
  end

  def send_login(username, ip)
	   mail(subject:"#{username} s'est connecté depuis : #{ip}", to:"philippe.nougaillon@gmail.com" )
  end

  def send_info(user, password)
	   @user = user
     @password = password
	   mail(subject:"Vos identifiants openCantine", to:@user.username) 
  end

end
