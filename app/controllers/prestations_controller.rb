# encoding: utf-8

class PrestationsController < ApplicationController

  before_filter :check, :only => ['edit', 'edit_from_enfants']
  skip_before_filter :check_authentification, :only => [:new_manual, :new_manual_calc]

  layout :determine_layout, :except => ['create', 'refresh', 'ajaxupdate', 'new_manual_calc']

  def check
    @presta = Prestation.find(params[:id])
    @enfant = Enfant.find(@presta.enfant_id)
    unless Famille.where("id = ? AND mairie_id = ?", @enfant.famille_id, session[:mairie]).any?
       redirect_to :action => 'index'
    end
  rescue
    redirect_to :action => 'index'
  end

  def determine_layout
    if params[:action] == 'print'
      "printer"
    else
      if session[:famille_id]
        "moncompte"
      else
        "standard"
      end
    end
  end

  # GET /prestations
  # GET /prestations.xml
  def index
    @images = get_etat_images

    params[:sort] ||= 'date, enfants.classe, familles.nom, enfants.prenom'
	  refresh 	 
  end

  def refresh
    if session[:prestation_date]
      params[:prestation_date] ||= session[:prestation_date]
    else
      params[:prestation_date] ||= Date.today.to_s(:fr)
    end

    if session[:periode]
      params[:periode] ||= session[:periode]
    else  
      params[:periode] ||= 'jour'
    end
 
    unless params[:sort].blank?
      sort = params[:sort]
      if session[:order_by] == sort
         sort = sort.split(" ").last == "DESC" ? sort.split(" ").first : sort + " DESC"   
      end  
      session[:order_by] = sort
    end
    @prestations = Prestation.search(params[:prestation_date], params[:classe], session[:mairie], sort, params[:periode])
    @classrooms  = Ville.find(session[:mairie]).classrooms

    session[:prestation_date] = params[:prestation_date]
    session[:periode] = params[:periode]   
  end

  def print
	   @images = get_etat_images
     @prestations = Prestation.search(params[:search], params[:classe], session[:mairie], 'date,enfants.classe,familles.nom,enfants.prenom', params[:periode])
     @classrooms  = Ville.find(session[:mairie]).classrooms
  end

  def editions
    @date = params[:search] unless params[:search].blank?
    @classe = params[:classe] unless params[:classe].blank?
    @periode = params[:periode] 
    @totaux = params[:totaux] unless params[:totaux].blank?
    case @periode
    when "jour" 
      @titre = "Liste des prestations du #{@date}"
    when "semaine" 
      @titre = "Liste des prestations du #{@date} au #{@date.to_date + 1.week}"
    when "mois" 
      @titre = "Liste des prestations du mois"
    else
      @titre = "Liste des prestations"
    end  
  end  

  # GET /prestations/1
  # GET /prestations/1.xml
  def show
    @prestation = Prestation.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @prestation }
    end
  end

  # GET /prestations/new
  # GET /prestations/new.xml
  def new
    @prestation = Prestation.new
    @enfants = []
    if params[:famille_id]
      @enfants = Famille.find(params[:famille_id]).enfants
    else
      @enfants << Enfant.find(params[:enfant_id])
    end
    @prestation.enfant_id = @enfants.first.id

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @prestation }
    end
  end

  # GET /prestations/1/edit
  def edit
    @prestation = Prestation.find(params[:id])
    @enfant = Enfant.find(@prestation.enfant_id)
    @famille = Famille.find(@enfant.famille_id)
	  @images = get_etat_images
  end

  # GET /prestations/1/edit
  def edit_from_enfants
    @prestation = Prestation.find(params[:id])
    params[:enfant_id] = @prestation.enfant_id
    @enfant  = Enfant.find(@prestation.enfant_id)
    @famille = Famille.find(@enfant.famille_id)
    @images = get_etat_images
  end

  def is_weekday?(date)
    date.wday != 0 && date.wday != 6
  end
  
  def days_in_month(date)
    year = date.year
    month = date.month
    d = (Date.new(year, 12, 31) << (12-month)).day
    return d
  end

  # POST /prestations
  # POST /prestations.xml
  def create
    @prestation_foo = Prestation.new(prestation_params)
	  @prestation_date = params[:prestation_date]
    ajouts = jours = erreurs = 0

    unless @prestation_date.blank?
       unless params[:famille_id].blank?
          @enfants = Famille.find(params[:famille_id]).enfants
       else
          @enfants = Enfant.where(id:@prestation_foo.enfant_id)
       end

       mairie = Ville.find(session[:mairie])
       vacances = mairie.vacances 

       #logger.debug "[ DEBUG ] enfant: #{@enfants.count}"

       @enfants.each do |enfant|
          start_date = @prestation_date.to_date
          #logger.debug "[ DEBUG ] #{enfant.prenom} : #{start_date}"

          if (params[:toutlemois] or params[:toutelannee]) and (params[:lundi] or params[:mardi] or params[:mercredi] or params[:jeudi] or params[:vendredi])
              #logger.debug "[ DEBUG ] #{enfant.prenom} : #{start_date} TEST OK"

      			  ndays = 5
              ndays = days_in_month(start_date) - (start_date.day - 1) if params[:toutlemois]

              # TODO: prendre le dernier de cours dans une table (vacances ???)
              ndays = (Date.parse("2019-07-07") - start_date).to_i if params[:toutelannee]
		
              date = start_date
              ndays.times do
                 wday = date.wday  
                 #logger.debug "[ DEBUG ] #{date} ndays = #{ndays}"
                 if is_weekday?(date)
                    # passe au jour suivant si vacances mais "appliquer si vacances" pas coché
                    en_vacances = vacances.where("debut <= ? AND fin >= ?", date.to_s(:en), date.to_s(:en)).any?
                    if (params[:en_vacances] == 'non' and en_vacances) or (params[:en_vacances] == 'oui' and !en_vacances)
                      #logger.debug "[ DEBUG ] #{date} Vacances #{params[:en_vacances]} NEXT !"
                      date = date + 1.day
                      next
                    end
                      
                    if (params[:lundi] and wday == 1) or (params[:mardi] and wday == 2) or (params[:mercredi] and wday == 3) or (params[:jeudi] and wday == 4) or (params[:vendredi] and wday == 5)
                      @prestation = Prestation.new(prestation_params)
                      @prestation.enfant_id = enfant.id
                      @prestation.date = date
                      @prestation.totalP = 0.00
                      @prestation.totalA = 0.00
                      @prestation.log_changes(0, session[:user])
        						  if @prestation.save
                         ajouts += 1
                      else 
                        erreurs += 1   
        						  end
                      jours += 1
                   end
                 end
                 date = date + 1.day
              end
            end
        end
        
        flash[:notice] = "#{ajouts} prestations ajoutées sur #{jours} jours ouvrés, #{erreurs} doublon(s)."
    
        if @famille_id
          redirect_to :controller => 'familles', :action => 'show', :id => @famille_id
        else
          redirect_to :controller => 'prestations', :action => 'new', :enfant_id => @enfants.first.id
        end
    else
       flash[:warning] = 'Veuillez saisir une date de début !'
       redirect_to :action => "new", :enfant_id => @prestation_foo.enfant_id
    end
  end

  def calendrier
  end

  # PUT /prestations/1
  # PUT /prestations/1.xml
  def update
    @prestation = Prestation.find(params[:id])
    @prestation.attributes = prestation_params
    @prestation.log_changes(1, session[:user])

    respond_to do |format|
      if @prestation.save(validate:false)
        flash[:notice] = 'Prestation modifiée.'
        format.html { redirect_to :action => 'index'  }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @prestation.errors, :status => :unprocessable_entity }
      end
    end
  end

   # GET /prestations/1/edit
  def test
    @prestation = Prestation.find(params[:id])
  end

  def ajaxupdate
    @prestation = Prestation.find(params[:id])
    respond_to do |format|
      format.js
    end
  end

  # PUT /prestations/1
  # PUT /prestations/1.xml
  def update_from_enfants
    @prestation = Prestation.find(params[:id])
    @prestation.attributes = prestation_params
    @prestation.log_changes(1, session[:user])

    respond_to do |format|
      if @prestation.save(validate:false)
        flash[:notice] = 'Prestation modifiée.'
        format.html { redirect_to :controller => 'enfants', :id => @prestation.enfant_id, :action => "show" }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @prestation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /prestations/1
  # DELETE /prestations/1.xml
  def destroy
    @prestation = Prestation.find(params[:id])
    @prestation.log_changes(2, session[:user])
    @prestation.destroy

    respond_to do |format|
      format.html { redirect_to :controller => 'enfants', :action => 'show', :id => @prestation.enfant_id }
      format.xml  { head :ok }
    end
  end

  def new_manual
    @duree = Prestation.duree_garderie
    @duree_matin = Prestation.duree_garderie_matin
    @duree_soir = Prestation.duree_garderie_soir

    session[:lastparams] =[]
    @mois = params[:mois]
    @year = params[:year]
    if @mois.to_i > 1
       @mois_down = @mois.to_i - 1
       @year_down = @year
    else
       @mois_down = 12
       @year_down = @year.to_i - 1
    end
    if @mois.to_i < 12
       @mois_up = @mois.to_i + 1
       @year_up = @year
    else
       @mois_up = 1
       @year_up = @year.to_i + 1
    end
    date = Date.new(@year.to_i, @mois.to_i, 1)
    @days=[]
    days_in_month(date).times {
      @days.push(date) if is_weekday?(date)
      date = date + 1.day
    }

    if session[:famille_id] # portail parent, TEST SI ENFANT DANS LA FAMILLE CONNECTEE
      @famille = Famille.find(session[:famille_id])
      @enfant = Enfant.find(params[:id])

      logger.debug "[DEBUG] Check: #{session[:famille_id]} #{@famille.enfants.include?(@enfant)}"

      unless @famille.enfants.include?(@enfant)
        flash[:warning] = "Enfant non autorisé..."
        redirect_to "/moncompte"
        return
      end
    else
      if params[:famille_id]
         @famille_id = params[:famille_id]
         @famille = Famille.find(@famille_id) 
         @enfants = @famille.enfants
         @enfant = @enfants[0]	
      else
         @enfant = Enfant.find(params[:id])
         @famille = Famille.find(@enfant.famille_id) 
      end
    end  

    @mairie = Ville.find(@famille.mairie_id)

    #charge le module Facture de cette mairie
    #load "Facture_modules/#{@mairie.FactureModuleName}"

    sumP  = @famille.factures.sum('montant')
    sumIn = @famille.paiements.sum('montant')
    @solde = sumIn - sumP

    respond_to do |format|
        format.html
        format.js
    end
    
  end

  #calcul les prestations ajoutées ou supprimées dans grille de saisie manuelle
  def new_manual_calc
    @mois = params[:mois]
    @year = params[:year]
    @solde = params[:solde].to_f
    @total = 0.00
    supprimees = []

    # test si l'utilisateur a décoché ?
    if session[:lastparams]
      supprimees = session[:lastparams] - params.keys
      #logger.debug "[DEBUG] suppr: #{supprimees}"
    end
    session[:lastparams] = params.keys
    #logger.debug "[DEBUG] last params: #{session[:lastparams]}"

    if params[:famille_id]
       @famille_id = params[:famille_id]
       @enfants = Enfant.where(famille_id:@famille_id)
    else
       @enfants = Enfant.where(id:params[:enfant_id])
    end

    @enfants.count.times { |i|
        @enfant = @enfants[i]
        #retourne le tarif
        @tarif = Facture.best_tarif(@enfant)
	      date = Date.new(@year.to_i, @mois.to_i, 1)
        #logger.debug "Date:#{date} "

        # supprime les décochés
        if supprimees.any? 
           keys = supprimees.first.split(".")  
           d = Date.new(@year.to_i, @mois.to_i, keys.first.to_i)

           @p = Prestation.where(enfant_id:@enfant.id, date:d).first
           @p[keys.last] = '0'
           @p.log_changes(1, session[:user])
           @p.save

           supprimees = []            
        end
           
        days_in_month(date).times {
          day = date.day
          #logger.debug "Day loop #{day}"

          if params[:"#{day}.repas"] or params[:"#{day}.garderieAM"] or params[:"#{day}.garderiePM"] or
            params[:"#{day}.centreAM"] or params[:"#{day}.centrePM"] or params[:etude]

            #logger.debug "Day loop :#{@year}-#{@mois}-#{day}"

            # test si date est dans une période de vacance
            # @vacances = Vacance.find(:all, :conditions => ["debut <= ? AND fin >= ? AND mairie_id = ?", date.to_s(:en), date.to_s(:en), session[:mairie]])

            @prestation = Prestation.where(enfant_id:@enfant.id, date:date).first
            if @prestation.nil?
               @prestation = Prestation.new
               @prestation.enfant_id = @enfant.id
               @prestation.date = date
            end
            @prestation.repas = '1' if params[:"#{day}.repas"]

            if params[:select][:"#{day}.garderieAM"] and params[:select][:"#{day}.garderieAM"] != "" 
              @prestation.garderieAM = params[:select][:"#{day}.garderieAM"]
            else
              @prestation.garderieAM = '1' if params[:"#{day}.garderieAM"]
            end 

           if params[:select][:"#{day}.garderiePM"] and params[:select][:"#{day}.garderiePM"] != "" 
              @prestation.garderiePM = params[:select][:"#{day}.garderiePM"]
            else
              @prestation.garderiePM = '1' if params[:"#{day}.garderiePM"]
            end 

            @prestation.centreAM = '1' if params[:"#{day}.centreAM"]
            @prestation.centrePM = '1' if params[:"#{day}.centrePM"]
            @prestation.etude = '1' if params[:etude] and ( date.wday != 3 and date.wday != 6 and date.wday != 0 and @vacances.empty?)
            @prestation.totalA = 0.00
            @prestation.log_changes(0, session[:user])
            #logger.info "[DEBUG] #{@prestation.changes}"  
            @prestation.save

            # calcul prestations type 1 ' Normale
            nbr_prestation = {'Repas' => 0,'GarderieAM' => 0,'GarderiePM' => 0, 'CentreAM' => 0, 'CentrePM' => 0, 'CentreAMPM' => 0, 'Etude' => 0, 'MntRepas' => 0,'MntGarderieAM' => 0,'MntGarderiePM' => 0, 'MntCentreAM' => 0, 'MntCentrePM' => 0, 'MntCentreAMPM' => 0, 'MntEtude' => 0 ,'JoursRepas' => "",'JoursGarderieAM' => "",'JoursGarderiePM' => "", 'JoursCentreAM' =>"", 'JoursCentrePM' => "", 'JoursCentreAMPM' => "", 'JoursEtude' => "",'PrixCentreAMPM' => 0, 'PrixCentreAM' => 0, 'PrixCentrePM' => 0}
            nbr_prestation = Facture.calc_prestation(nbr_prestation, @prestation, @tarif, date)

            #nbr_prestation = @prestation.calc_prestation(nbr_prestation)
            total_prestations = nbr_prestation['MntRepas'] + nbr_prestation['MntGarderieAM'] + nbr_prestation['MntGarderiePM'] + nbr_prestation['MntCentreAM'] + nbr_prestation['MntCentrePM'] + nbr_prestation['MntCentreAMPM'] + nbr_prestation['Etude']
            @total = @total + total_prestations
            @prestation.totalP = total_prestations
            #@tarif = @prestation.tarif

      		  @prestation.save
  	      end
          date = date + 1.day
        }
    }

    flash[:notice] = "Prestations enregistrées. Total: #{@total.round(2)} €"
    redirect_to :back
  end


  def new_manual_calc_test
    if params[:famille_id]
       @famille_id = params[:famille_id]
       @enfants = Enfant.where(famille_id:@famille_id)
    else
       @enfants = Enfant.find(:all, :conditions => ["id = ? ", params[:enfant_id]])
    end

    @enfant = @enfants[0]
    @famille = Famille.find(@enfants[0].famille_id)

    @sumP  = @famille.factures.sum('montant')
    @sumIn = @famille.paiements.sum('montant')
    @solde = @sumIn - @sumP
    @total = 0.00

    #{}"enfant_id"=>"650", "mois"=>"10", "year"=>"2014", 
    #{}"9RepasAM"=>"on", "10RepasAM"=>"on", "13RepasAM"=>"on", "14RepasAM"=>"on", 
    #{}"15RepasAM"=>"on", "16RepasAM"=>"on"

    mois = params[:mois]
    year = params[:year]

    params.each do |param|
      key = param.first
      value = param.last
      if value == 'on'
        d = key.split(".").first
        type = key.split(".").last
        date = Date.new(year.to_i, mois.to_i, d.to_i)
        #logger.debug "!!! DATE : #{date} Type: #{type}"
        presta = Prestation.first_or_create(enfant_id:params[:enfant_id], date:date)
        #logger.debug "!!! Presta : #{presta.inspect}"
      end  
    end
        
    respond_to do |format|
       format.html
       format.js
    end
  end

  def new_manual_classroom
    @classrooms = Ville.find(session[:mairie]).classrooms
    @date = params[:date]
    @classe = params[:classe]
    @duree = Prestation.duree_garderie
    @duree_matin = Prestation.duree_garderie_matin
    @duree_soir = Prestation.duree_garderie_soir

    @kids_to_show=[]
	  @kids_to_show_presta=[]

	  @enfants = Enfant.where(classe:@classe).joins(:famille).order('familles.nom')
	  @enfants.each do |e|
		  @kids_to_show.push(e)
		  @presta = e.prestations.where("date = ? and facture_id is null", @date.to_date.to_s(:en)).last
		  if @presta
		     @kids_to_show_presta.push(@presta)
		  else
		     @kids_to_show_presta.push(nil)
		  end
    end
  end
  
  def new_manual_classroom_check
    if params[:date] and params[:classe] and params[:check]
    	@date   = params[:date] 
    	@classe = params[:classe] 
      @ajouts = 0
      params[:check].keys.each do | param |
        enfant_id = param.split('.').first.to_i
        presta = param.split('.').last

        @prestation = Prestation.find_or_create_by(date:@date.to_date.to_s(:en), enfant_id:enfant_id)
        @prestation.repas = '1' if presta == 'repas' and @prestation.repas != '1'

        if presta == 'garderieAM'
          if params[:select].include?(param) and params[:select][param] != "" 
            @prestation.garderieAM = params[:select][param]
          else
            @prestation.garderieAM = '1'
          end 
        end  
        if presta == 'garderiePM' 
          if params[:select].include?(param) and params[:select][param] != "" 
            @prestation.garderiePM = params[:select][param]
          else
            @prestation.garderiePM = '1'
          end
        end 

        @prestation.centreAM = '1' if presta == 'centreAM' and @prestation.centreAM != '1'
        @prestation.centrePM = '1' if presta == 'centrePM' and @prestation.centrePM != '1'

        @ajouts += 1 if @prestation.changes.any?
        @prestation.log_changes(0, session[:user])
        @prestation.save
      end
      flash[:notice] = "#{@ajouts} prestation(s) enregistrée(s)..."
    end
    redirect_to new_manual_classroom_path(date:params[:date], classe:params[:classe])
  end 

  def stats_mensuelle_params
	  @classrooms = Ville.find(session[:mairie]).classrooms
  end

  def stats_mensuelle
  	@stats_date = params[:stats][:an] + '-' + params[:stats][:mois] + '-01'
  	@prestation_date = @stats_date.to_date
  	@prestations = Prestation.search(@prestation_date, params[:stats][:classe], session[:mairie], 'enfants.nomfamille, enfants.prenom', true)
  	
  	if @prestations.first
  		@classrooms = Ville.find(session[:mairie]).classrooms
  		@datedebut  = @prestation_date.to_date.at_beginning_of_month
  		@datefin = @prestation_date.to_date.at_end_of_month	
  		@classe = @prestations.first.enfant.classe
  		@enfant_id = @prestations.first.enfant.id
  	else
  		flash[:notice] = "Pas de prestations ce mois là."
  		redirect_to "/prestations/stats_mensuelle_params/0"
  	end
  end	

  def action
    if params[:action_name] == "Supprimer" and params[:prestation_ids]
      params[:prestation_ids].keys.each do | id |
        Prestation.find(id).destroy
      end
      flash[:notice] = "Prestation(s) supprimée(s)"
    end
    redirect_to prestations_path
  end

  private
  # Never trust parameters from the scary internet, only allow the white list through.
    def prestation_params
      params.require(:prestation).permit(:enfant_id,:facture_id,:etude,:date,:totalA,:totalP,:garderieAM,:garderiePM,:centreAM,:centrePM,:repas)
    end

end
