# encoding: utf-8

class AdminController < ApplicationController

  layout "standard"

  def stats
     @users = User.find(:all, :order => 'lastconnection DESC')
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
      @u.lastconnection = Time.now
      @u.save
      session[:user] = @u.id
      session[:user_readwrite] = @u.readwrite
      session[:mairie] = @u.mairie_id
	else
	  flash[:notice] = "Compte inconnu ! Pour utiliser le compte de démonstration, entrez 'demo' et 'demo'."
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
    flash[:notice] = "Session #{@user.username} terminée." 
  end

  def user_edit
    @user = User.find(session[:user])
  end
  
  def user_update
    @user = User.find(session[:user])
    respond_to do |format|
     if @user.update_attributes(params[:user]) and @user.mairie_id != 2
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
    mairie = session[:mairie]
    @mairie = Ville.find(mairie)
    @classrooms = Classroom.find_all_by_mairie_id(mairie, :order => 'nom')
    @tarifs = Tarif.find_all_by_mairie_id(mairie, :order => "memo")
    @users = User.find_all_by_mairie_id(mairie, :order => "username")
    @facture_chrono = FactureChrono.find_by_mairie_id(mairie)
    @vacances = Vacance.find_all_by_mairie_id(mairie, :order => 'debut')
    @enfants= Enfant.find_by_sql("SELECT id FROM enfants WHERE famille_id IN (SELECT id FROM familles WHERE mairie_id= #{session[:mairie]} )")
  end

  def users_admin
	@users = User.find_all_by_mairie_id(session[:mairie], :order => "username")
  end

  def user_add
	@user = User.new
	@user.username = params[:user][:username]
	@user.password = params[:user][:password]
    @user.mairie_id = session[:mairie]
	@user.lastconnection = Date.today
	@user.lastchange = Date.today

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

  def points_forts

  end

end
