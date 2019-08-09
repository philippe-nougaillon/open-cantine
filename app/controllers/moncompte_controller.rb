# encoding: utf-8

class MoncompteController < ApplicationController

  skip_before_action :check_authentification
 
  layout :determine_layout

  def index
    # sign out
    session[:mairie] = nil if session[:mairie]
    session[:user] = nil if session[:user]
    redirect_to :action => "famillelogin"
  end

  def famillelogin
    unless params[:email].blank? and params[:password].blank?

      if params[:email].to_i > 0
        @famille = Famille.find(params[:email])
      else
        @famille = Famille.find_by(email:params[:email])
      end

      if @famille and @famille.mairie.portail > 0
        if @famille.password == params[:password]
          @famille.lastconnection = Time.now
          @famille.log_changes(1, nil)
          @famille.save
          session[:famille_id] = @famille.id
          flash[:notice] = "Dernière connection le #{@famille.lastconnection.to_s(:fr)}" if @famille.lastconnection
          redirect_to :action => "familleshow"
        else
          flash[:notice] = 'Mot de passe incorrect'
        end
      else
        flash[:notice] = 'Identifiant ou mot de passe inconnu'
      end
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
      UserMailer.send_password(@famille).deliver_now
      flash[:notice] = "Un nouveau mot de passe vient d'être envoyé à #{@famille.email}"
    else
      flash[:notice] = "Adresse email inconnue..."
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
    if session[:famille_id]
      @images = ["","yes.png","no.jpeg","orange.jpeg","cancel.jpeg","yes.png","yes.png","yes.png"]
      @famille = Famille.find(session[:famille_id])
      @ville = @famille.mairie
      releve = []

      @famille.factures.each do |f|
        releve << { date:f.date.to_date, type:"Facture", ref:f.ref, mnt:f.montant, solde:0 }
      end
      @famille.paiements.each do |p|
        releve << { date:p.date.to_date, type:"Paiement", ref:p.ref, mnt:p.montant, solde:0 }
      end

      @releve = releve.sort { |a,b| a[:date] <=> b[:date] }
      @solde = 0.00 
      @debit = 0.00 
      @credit = 0.00

      @releve.each do |l|
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

      @releve = @releve.last(5) unless params[:all] == '1'

    else
      redirect_to action:"famillelogin" 
    end

  end

  def famillelogout
    session[:famille_id] = nil
    flash[:notice] = "Vous avez bien été déconnecté(e)"
    redirect_to :action => "famillelogin"
  end

  def famillefacture
    require 'factures.rb'
    facture = Facture.find_by_ref(params[:ref])
    return if facture.famille_id != session[:famille_id]

    respond_to do |format|
      format.pdf do
        pdf = FacturePdf.new([facture.id])
        send_data pdf.render, 
              :type => "application/pdf", 
              :filename => "Facture_#{facture.ref}_#{facture.created_at.strftime("%d/%m/%Y")}.pdf"
      end
    end        
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
