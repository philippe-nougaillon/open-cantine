# encoding: utf-8

class MoncompteController < ApplicationController

  skip_before_filter :check_authentification, :except => [:famillefacture]
 
  layout :determine_layout

  def index
    redirect_to :action => "famillelogin"
  end

  def famillelogin
    if request.post?
      return if params[:email].blank?

      @famille = Famille.where(email:params[:email]).first
      @ville = @famille.mairie
      if @famille and @ville.portail > 0
        if @famille.password == params[:password]
          @famille.lastconnection = Time.now
          @famille.log_changes(1, nil)
          @famille.save
          session[:famille_id] = @famille.id
          flash[:notice] = "Dernière connection le #{@famille.lastconnection.to_s(:fr)}" if @famille.lastconnection
          redirect_to :action => "familleshow"
        else
          flash[:warning] = 'Mot de passe incorrect'
        end
      else
        flash[:warning] = 'Accès non autorisé, veuillez contacter le service périscolaire'
      end
    else
      redirect_to :action => "familleshow" if session[:famille_id]
    end
  end

  def mdpoublie

  end

  def mdpoublie_renvoyer
    return if params[:email].blank?
    @famille = Famille.where(email:params[:email]).first
    if @famille
      # envoi le mot de passe 
      @famille.update_attributes(password:random_password)
      UserMailer.send_password(@famille).deliver
      flash[:notice] = "Un nouveau mot de passe vient d'être envoyé à #{@famille.email}"
    else
      flash[:warning] = "Adresse email inconnue..."
    end   
    redirect_to :action => "famillelogin"
  end

  def famillelogin_iphone
      if request.post?
         pass = params[:email]
         @famille = Famille.find_by_email(params[:email])
         if @famille
           if params[:password].blank? and @famille.password.blank?
              password = random_password
              @famille.password = password
              @famille.save
              UserMailer.deliver_send_password(@famille)
              flash[:notice] = "Un nouveau mot de passe vient d'être envoyé à #{@famille.email}"
           else
              if @famille.password == params[:password]
                if @famille.lastconnection
                   flash[:notice] = "Bienvenue! Dernière connection: #{@famille.lastconnection.to_s(:fr)}"
                end
                @famille.lastconnection = Time.now
                @famille.save
                session[:famille] = @famille.id
                redirect_to :action => "familleindex_iphone", :target => '_self'
              else
                flash[:warning] = 'Mot de passe incorrect !'
                flash[:notice] = nil
              end
           end
         else
           flash[:warning] = 'Email ou mot de passe inconnu !'
         end
      end
  end

  def familleindex_iphone
    @famille = Famille.find(session[:famille])
  end

  def familleshow
    @images = ["","yes.png","no.jpeg","orange.jpeg","cancel.jpeg","yes.png","yes.png","yes.png"]
    @famille = Famille.find(session[:famille_id])
    @ville = @famille.mairie
    releve = []

    for f in @famille.factures
      releve << { date:f.date.to_date, type:"Facture", ref:f.ref, mnt:f.montant, solde:0 }
    end
    for p in @famille.paiements
      releve << { date:p.date.to_date, type:"Paiement", ref:p.ref, mnt:p.montant, solde:0 }
    end

    @releve = releve.sort { |a,b| a[:date] <=> b[:date] }
    @solde = 0.00
    @debit = 0.00
    @credit = 0.00

    for l in @releve
      mnt = l[:mnt]
      if l[:type] == "Facture"
        @debit += mnt
        @solde -= mnt
      else
        @credit += mnt
        @solde += mnt
      end
      l[:solde] = @solde
    end 

    unless params[:all] == '1'
      @releve = @releve[-5,5]
    end

  end

  def famillelogout
    session[:famille_id] = nil
    flash[:notice] = "Vous avez bien été déconnecté"
    redirect_to :action => "famillelogin"
  end

  def famillefacture
    require 'factures.rb'
    facture = Facture.find_by_ref(params[:ref])
    return if facture.famille_id != session[:famille_id]

    pdf = FacturePdf.new(facture, facture.ville, view_context)
    send_data pdf.render, :type => "application/pdf", 
          :filename => "Facture_#{facture.ref}_#{facture.created_at.strftime("%d/%m/%Y")}.pdf"
  end

 private
  def determine_layout
    return iphone_format? ? "iphone" : "moncompte"
  end

  def random_password(size = 5)
    chars = (('A'..'Z').to_a + ('0'..'9').to_a) - %w(i o 0 1 l 0)
    (1..size).collect{|a| chars[rand(chars.size)] }.join
  end
 
end
