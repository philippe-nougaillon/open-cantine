# encoding: utf-8

class AdminController < ApplicationController

  skip_before_filter :check_authentification

  layout "standard"

  def stats
    @users = User.order('lastconnection DESC').limit(20)
  end

  def signin
    @blogs   = Blog.search(params[:page])
    respond_to do |format|
    	format.html 
    	format.js
	  end
  end

  def check_user
  	if params[:demo] 
      @u = User.authenticate2('demo', 'demo')
  	else
      @u = User.authenticate2(params[:user][:username], params[:user][:password])
  	end

    if @u 
      session[:user] = @u.id
      session[:user_readwrite] = @u.readwrite
      session[:mairie] = @u.mairie_id
      @u.lastconnection = Time.now
      @u.log_changes(1, @u.id)
      @u.save
      flash[:notice] = "B i e n v e n u e"
	  else
	    flash[:notice] = "Compte inconnu..."
    end

	  respond_to do |format|
  	  format.js { render :js => "window.location = '/familles/index'" if @u }
	    format.html { redirect_to familles_path }	
	  end
  end

  def signout
    @user = User.find(session[:user])
    session[:user] = nil
    redirect_to :controller => 'admin', :action => 'signin'
    flash[:notice] = "Session '#{@user.username}' terminée. A bientôt..." 
  end

  def user_edit
    @user = User.find(session[:user])
  end
  
  def user_update
    @user = User.find(session[:user])
    @user.attributes = params[:user]
    @user.log_changes(1, session[:user])
    respond_to do |format|
       if @user.save(validate:false) and @user.mairie_id != 2
          @user.lastchange = Time.now
          @user.save
          flash[:notice] = "Utilisateur modifié..."
          format.html { redirect_to :action => "setup", :controller => "admin" }
          format.xml  { head :ok }
        else
          flash[:warning] = 'Modification annulée. Peut être essayez-vous de changer le mot de passe du compte de démonstration ?'
          format.html { render :action => "user_edit" }
          format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
        end
    end
  end

  def backup
    @filename = "#{Date.today.to_s(:fr)}-#{session[:mairie]}-backupmacantine.txt"

    cmd = "'select * from villes where id=#{session[:mairie]}'"
    system("echo '******* VILLES *************' > public/#{@filename}")
    system("mysql -u root -pAltecLansing2009  -e #{cmd} CANTINE >> public/#{@filename}")

    cmd = "'select * from familles where mairie_id=#{session[:mairie]}'"
    system("echo '******* FAMILLES *************' >> public/#{@filename}")
    system("mysql -u root -pAltecLansing2009  -e #{cmd} CANTINE >> public/#{@filename}")

    cmd = "'select * from enfants where famille_id in (select id from familles where mairie_id=#{session[:mairie]})'"
    system("echo '******* ENFANTS *************' >> public/#{@filename}")
    system("mysql -u root -pAltecLansing2009  -e #{cmd} CANTINE >> public/#{@filename}")

    cmd = "'SELECT * FROM prestations where enfant_id in (select id from enfants where famille_id in (select id from familles where mairie_id =#{session[:mairie]}))'"
    system("echo '******* PRESTATIONS *************' >> public/#{@filename}")
    system("mysql -u root -pAltecLansing2009  -e #{cmd} CANTINE >> public/#{@filename}")

    cmd = "'select * from factures where mairie_id=#{session[:mairie]}'"
    system("echo '******* FACTURES *************' >> public/#{@filename}")
    system("mysql -u root -pAltecLansing2009  -e #{cmd} CANTINE >> public/#{@filename}")

    cmd = "'select * from facture_lignes where facture_id in (select id from factures where mairie_id=#{session[:mairie]})'"
    system("echo '******* FACTURE_LIGNES *************' >> public/#{@filename}")
    system("mysql -u root -pAltecLansing2009  -e #{cmd} CANTINE >> public/#{@filename}")

    cmd = "'select * from paiements where mairie_id=#{session[:mairie]}'"
    system("echo '******* PAIEMENTS *************' >> public/#{@filename}")
    system("mysql -u root -pAltecLansing2009  -e #{cmd} CANTINE >> public/#{@filename}")

    cmd = "'select * from classrooms where mairie_id=#{session[:mairie]}'"
    system("echo '******* CLASSES *************' >> public/#{@filename}")
    system("mysql -u root -pAltecLansing2009  -e #{cmd} CANTINE >> public/#{@filename}")

    cmd = "'select * from users where mairie_id=#{session[:mairie]}'"
    system("echo '******* USERS *************' >> public/#{@filename}")
    system("mysql -u root -pAltecLansing2009  -e #{cmd} CANTINE >> public/#{@filename}")
     
    cmd = "'select * from tarifs where mairie_id=#{session[:mairie]}'"
    system("echo '******* TARIFS *************' >> public/#{@filename}")
    system("mysql -u root -pAltecLansing2009  -e #{cmd} CANTINE >> public/#{@filename}")
  end

  def backupall
    @user = User.find(session[:user])
    if @user.username == "capcod"
      @filename = "#{Date.today.to_s(:fr)}-all-backupmacantine.sql"
      system("mysqldump -u root -pAltecLansing2009 CANTINE > public/#{@filename}")
    else
      flash[:warning] = "Vous n'êtes pas autorisé..."
      redirect_to :action => "setup"
    end
  end

  def setup
    @mairie = Ville.find(session[:mairie])
    @users = @mairie.users.order('username')
    @classrooms = @mairie.classrooms.order('nom')
    @tarifs = @mairie.tarifs.order('memo')
    @vacances = @mairie.vacances.order('debut')
  end

  def change_acces_portail
    #logger.debug "[DEBUG] @portail = #{params[:ville][:portail]}" 
    p = params[:ville][:portail]
    v = Ville.find(session[:mairie])
    if v.portail.to_s != p
      v.portail = p
      v.log_changes(1, session[:user])
      v.save(validate:false)
      flash[:notice] = "Mode d'accès au portail parents modifié avec succès..."
    end  
    redirect_to action:"setup"
  end  

  def users_admin
	  @users = User.find_all_by_mairie_id(session[:mairie], :order => "username")
  end

  def user_add
	  @user = User.new(username:params[:user][:username], password:params[:user][:password], readwrite:params[:user][:readwrite])
    @user.mairie_id = session[:mairie]
	  @user.lastconnection = DateTime.now
	  @user.lastchange = DateTime.now
    @user.log_changes(0, session[:user])

    if @user.save
      flash[:notice] = "Utilisateur ajouté."
    else
      flash[:warning] = "Erreur! Cet utilisateur existe déjà ?"
    end
    redirect_to :action => "users_admin"
  end

  def show_facturation_module
    @mairie = Ville.find(session[:mairie])
    mairie_facturation_module = @mairie.FacturationModuleName
    @facturation_module = IO.readlines("/home/phil/NetBeansProjects/Cantine/app/models/facturation_modules/#{mairie_facturation_module}")
  end

  def guide

  end

  def import

  end

  def import_do
    if params[:upload]
      require 'rake'
      Rake::Task.clear # necessary to avoid tasks being loaded several times in dev mode
      OpenCantine3::Application.load_tasks 

      #Save file to local dir
      filename = params[:upload].original_filename
      file_with_path = Rails.root.join('public', filename)
      File.open(file_with_path, 'wb') do |file|
          file.write(params[:upload].read)
      end

      # execute rake and capture output  
      @out = capture_stdout do
          Rake::Task['familles:import'].invoke(file_with_path, params[:save], session[:user])
      end

      # save output            
      File.open("public/Import_Familles-#{DateTime.now.to_s}.txt", "w") { |file| file.write @out }
    else
      flash[:notice] = "Manque le fichier source pour la mise à jour"
      redirect_to action: 'import'
    end
  end

  def points_forts

  end

  def download
    send_file "#{Rails.root}/public/#{params[:file_name]}", :type=>"application/text"
  end 

  def facturation_speciale
    @user = User.find(session[:user])
    @familles = @user.ville.familles.order(:nom)
    @facture = Facture.new(mairie_id:@user.mairie_id) 
  end

  def facturation_speciale_do
    @user = User.find(session[:user]) 
    @familles = @user.ville.familles.order(:nom)
    @facture = Facture.new(params[:facture])
    prochain = FactureChrono.where(mairie_id:@facture.mairie_id).first.prochain
    texte = @facture.ref
    @facture.ref = "#{Date.today.month.to_s}-#{Date.today.year}/#{prochain}"
    @facture.echeance = Date.today.at_end_of_month
    unless params[:facture][:famille_id].blank?
      unless @facture.valid?
        flash[:warning] = "Données insuffisantes pour continuer"
        render action: "facturation_speciale" 
      else
        @facture.log_changes(0, @user.id)
        @facture.save
        FactureLigne.create(facture_id:@facture.id, texte:texte, qte:1, montant:@facture.montant, prix:@facture.montant) 
        FactureChrono.where(mairie_id:@facture.mairie_id).update_all(prochain:prochain + 1)
        flash[:notice] = "1 facture créée avec succès..."
        redirect_to factures_path
      end
    else
      @facture.famille_id = @familles.first.id
      unless @facture.valid?
        flash[:warning] = "Données insuffisantes pour continuer"
        render action: "facturation_speciale" 
      else
        @familles.each do |famille|
            prochain = FactureChrono.where(mairie_id:@facture.mairie_id).first.prochain
            f = @facture.dup
            f.famille_id = famille.id
            f.ref = "#{Date.today.month.to_s}-#{Date.today.year}/#{prochain}" 
            f.log_changes(0, @user.id)
            f.save
            FactureLigne.create(facture_id:f.id, texte:texte, qte:1, montant:f.montant, prix:f.montant)
            FactureChrono.where(mairie_id:@facture.mairie_id).update_all(prochain:prochain + 1)  
        end    
        flash[:notice] = "#{@familles.count} factures créées avec succès..."
        redirect_to factures_path
      end
    end  
  end

end
