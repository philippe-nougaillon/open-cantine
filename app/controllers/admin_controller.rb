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
      @u = User.authenticate2('demo','demo')
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
  	  format.js { render :js => "window.location = '/familles'" if @u }
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
    if !@user.readwrite or @user.mairie_id == 2
      flash[:warning]= "Action non autorisée !"
      redirect_to root_url
      return
    end
  end
  
  def user_update
    @user = User.find(session[:user])
    @user.attributes = user_params
    if @user.save(validate:false) 
      @user.lastchange = Time.now
      @user.save
      flash[:notice] = "Utilisateur modifié..."
      redirect_to :action => "setup", :controller => "admin"
    else
      flash[:warning] = 'Modification annulée'
      render :action => "user_edit"
    end
  end

  # DELETE 
  def user_destroy
    current_user = User.find(session[:user])
    unless current_user.readwrite 
      redirect_to root_url, notice: "Action non autorisée !"
      return
    end
    @user = User.find(params[:id])
    if current_user.ville.users.include?(@user) # fait parti des utilisateurs du même compte
      @user.destroy 
      @user.logs.destroy_all
    end

    respond_to do |format|
      format.html { redirect_to(admin_users_admin_path) }
      format.xml  { head :ok }
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
	  @users = User.where(mairie_id:session[:mairie]).order(:username)
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

 private
  # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:username, :mairie_id, :lastconnection, :lastchange, :readwrite, :password)
    end
end
