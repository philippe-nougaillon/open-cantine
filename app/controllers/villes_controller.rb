# encoding: utf-8

class VillesController < ApplicationController

  skip_before_filter :check_authentification, :only => [:nouveau_compte, :nouveau_compte_create]

  layout "standard"

  def nouveau_compte
    @ville = Ville.new
	flash[:notice] =""
  end	

  # POST /villes
  def nouveau_compte_create
  	@ville = Ville.new(ville_params)
    @ville.FacturationModuleName = "01-Standard.rb"
    @ville.newsletter = false

	if params[:antispam] != "26"
		flash[:warning] = 'Oups !?! Un peu de concentration, svp...'
		render :action => "nouveau_compte"
		return
	end
  
    if @ville.save
		u = User.new
		u.mairie_id = @ville.id
		u.username = @ville.email
		password = random_password()
		u.password = password
		u.lastconnection = Time.now
		u.lastchange = Time.now
		u.readwrite = true
		u.save

	 	prochain = FactureChrono.new
		prochain.mairie_id = @ville.id
		prochain.prochain = 1
		prochain.save

		tarif = Tarif.new
		tarif.type_id = 1
		tarif.mairie_id = @ville.id
		tarif.memo = "Tarif Général"
		tarif.RepasP = 2.24
		tarif.GarderieAMP = 1.00
		tarif.GarderiePMP = 1.00
		tarif.CentreAMP = 1.00
		tarif.CentrePMP = 1.00
		tarif.CentreAMPMP = 2.00
		tarif.Etude = 1.00
		tarif.save
	
		vacance = Vacance.new
		vacance.mairie_id = @ville.id
		vacance.nom = "NOEL"
		vacance.debut = "20.12.2014"
		vacance.fin = "03.01.2015"
		vacance.save

		classe = Classroom.new
		classe.mairie_id = @ville.id
		classe.nom = "CP"
		classe.referant = "La maîtresse du CP"
		classe.save

		famille = Famille.new
		famille.mairie_id = @ville.id
		famille.nom = "Famille de TEST"
		famille.adresse = "1, rue des petits champs"
		famille.cp = "93220"
		famille.ville = "GAGNY"
		famille.phone = "01.43.35.10.28"
		famille.save

		e = Enfant.new
		e.famille_id = famille.id
		e.nomfamille = famille.nom
		e.prenom = "Nicolas"
		e.dateNaissance = "01/01/2003"
		e.age = 7
		e.classe = classe.id
		e.save
		
		pr = Prestation.new
		pr.enfant_id = e.id
		pr.date = Time.now
		pr.repas = "1"
		pr.save

		# envoyer un mail au nouvel utilisateur
		UserMailer.send_info(u, password).deliver

		#ouverture de la session
		session[:user] = u.id
		session[:user_readwrite] = u.readwrite
		session[:mairie] = u.mairie_id
		redirect_to :controller => "familles"
		flash[:notice] = 'Bienvenue !'
	    UserMailer.send_login(u.username, request.env["HTTP_X_FORWARDED_FOR"] || request.remote_addr).deliver
    else
        render :action => "nouveau_compte" 
    end
  end
  
  # GET /villes/1/edit
  def edit
    @ville = Ville.find(session[:mairie])
  end

  def show
    redirect_to :controller => 'admin', :action => 'setup'
  end

  # PUT /villes/1
  # PUT /villes/1.xml
  def update
    @ville = Ville.find(session[:mairie])
    @ville.attributes = ville_params
    @ville.log_changes(1, session[:user])

    respond_to do |format|
      if @ville.save(validate:false)
        flash[:notice] = 'Modifications validées'
        format.html { redirect_to(:controller => 'admin', :action => 'setup') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @ville.errors, :status => :unprocessable_entity }
      end
    end
  end

 private
  	# Never trust parameters from the scary internet, only allow the white list through.
    def ville_params
      params.require(:ville).permit(:nom,:adr,:cp,:ville,:tel,:tarif2,:tarif3,:FacturationModuleName,:email,:newsletter,:logo_url,:portail)
    end  	

 	def random_password(size = 5)
    	chars = (('A'..'Z').to_a + ('0'..'9').to_a) - %w(i o 0 1 l 0)
    	(1..size).collect{|a| chars[rand(chars.size)] }.join
  	end
end
