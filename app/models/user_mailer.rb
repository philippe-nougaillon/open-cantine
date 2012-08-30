# encoding: utf-8

class UserMailer < ActionMailer::Base

  def send_password(famille)
    subject    'Pour consulter votre compte'
    recipients famille.email
    from       'contact@openCantine.fr'
    sent_on    Time.now
    body       :famille => famille
  end

  def send_invoice(ville, famille, facture)
    subject    "#{ville.nom} - Facture périscolaire"
    recipients famille.email
    from       ville.email
    sent_on    Time.now
    body       "Veuillez trouver ci-joint la facture #{facture.ref}."
    attachment :filename => 'Facture.pdf', :body => File.read(Rails.root + "/pdfs/#{facture.id}.pdf")
  end


  def send_login(username,ip)
    subject    "#{username} s'est connecté à openCantine.fr"
    recipients "philippe@capcod.com"
    from       'login@opencantine.fr'
    sent_on    Time.now
    body       "#{username} s'est connecté depuis : #{ip}"
  end

  def send_logout(username,ip)
    subject    "#{username} s'est déconnecté de openCantine.fr"
    recipients "philippe@capcod.com"
    from       'login@opencantine.fr'
    sent_on    Time.now
    body       "#{username} s'est déconnecté depuis : #{ip}"
  end

  def send_info(email)
    subject    "openCantine.fr - Vos identifiants de connexion"
    recipients  email
    from       'philippe@capcod.com'
    sent_on    Time.now
    body       "Un compte #{email} a bien été créé. Utilisez votre email comme identifiant et mot de passe pour vous connecter. Vous pouvez modifier votre mot de passe à tout moment."
  end
end
