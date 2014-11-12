# encoding: utf-8

class PrestationsController < ApplicationController

  before_filter :check, :only => ['edit', 'edit_from_enfants']
  skip_before_filter :check_authentification, :only => [:new_manual, :new_manual_calc]

  layout :determine_layout, :except => ['create', 'refresh', 'ajaxupdate', 'new_manual_calc']

  def check
    @presta = Prestation.find(params[:id])
    @enfant = Enfant.find(@presta.enfant_id)
    unless Famille.find(:first, :conditions => [" id = ? AND mairie_id = ?", @enfant.famille_id, session[:mairie]])
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

    if params[:pointage] and session[:user_readwrite]
      unless params[:classe].blank?
        session[:date]   = params[:prestation_date]
        session[:classe] = params[:classe]
        redirect_to '/presence'
      else
        flash[:notice] = "Veuillez choisir une classe"
        redirect_to prestations_path(prestation_date:params[:prestation_date])  
      end
    else
      params[:sort] ||= 'date,enfants.classe,familles.nom,enfants.prenom'
		  refresh 	 
	 end
  end

  def refresh
    params[:prestation_date] ||= Date.today.to_s(:fr)
    params[:periode] ||= 'jour'
 
    unless params[:sort].blank?
      sort = params[:sort]
      if session[:order_by] == sort
         sort = sort.split(" ").last == "DESC" ? sort.split(" ").first : sort + " DESC"   
      end  
      session[:order_by] = sort
    end
    @prestations = Prestation.search(params[:prestation_date], params[:classe], session[:mairie], sort, params[:periode])
    @classrooms  = Ville.find(session[:mairie]).classrooms
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
      @titre = "Liste des prestations au #{@date}"
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
    @prestation_foo = Prestation.new(params[:prestation])
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

       logger.debug "[ DEBUG ] #{@enfants.count}"

       @enfants.each do |enfant|
          start_date = @prestation_date.to_date
          logger.debug "[ DEBUG ] #{enfant.prenom} : #{start_date}"

          if (params[:toutlemois] or params[:toutelannee]) and (params[:lundi] or params[:mardi] or params[:mercredi] or params[:jeudi] or params[:vendredi])
      			  ndays = 5
              ndays = days_in_month(start_date) - (start_date.day - 1) if params[:toutlemois]
              ndays = (Date.parse("2015-07-04") - start_date).to_i if params[:toutelannee]
		
              date = start_date
              ndays.times do
                 wday = date.wday  
                 logger.debug "[ DEBUG ] #{date} ndays = #{ndays}"
                 if is_weekday?(date)
                    # passe au jour suivant si vacances mais "appliquer si vacances" pas coché
                    en_vacances = vacances.where("debut <= ? AND fin >= ?", date.to_s(:en), date.to_s(:en)).any?
                    if (params[:en_vacances] == 'non' and en_vacances) or (params[:en_vacances] == 'oui' and !en_vacances)
                       logger.debug "[ DEBUG ] #{date} Vacances #{params[:en_vacances]} NEXT !"
                       date = date + 1.day
                       next
                    end
                      
                    if (params[:lundi] and wday == 1) or (params[:mardi] and wday == 2) or (params[:mercredi] and wday == 3) or (params[:jeudi] and wday == 4) or (params[:vendredi] and wday == 5)
                      @prestation = Prestation.new(params[:prestation])
                      @prestation.enfant_id = enfant.id
                      @prestation.date = date
                      @prestation.totalP = 0.00
                      @prestation.totalA = 0.00
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
        
        flash[:notice] = "#{ajouts} prestations ajoutées sur #{jours} jours ouvrés, #{erreurs} doublon  (s)."
    
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

    respond_to do |format|
      if @prestation.update_attributes(params[:prestation])
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

    respond_to do |format|
      if @prestation.update_attributes(params[:prestation])
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
    @prestation.destroy

    respond_to do |format|
      format.html { redirect_to :controller => 'enfants', :action => 'show', :id => @prestation.enfant_id }
      format.xml  { head :ok }
    end
  end

  def new_manual
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
      famille = Famille.find(session[:famille_id])
      logger.debug "[DEBUG] Check: #{session[:famille_id]} #{famille.enfants.include?(@enfant)}"
      unless famille.enfants.include?(@enfant)
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

    #charge le module Facturation de cette mairie
    load "facturation_modules/#{@mairie.FacturationModuleName}"

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

    # test si l'utilisateur a décoché ?
    if session[:lastparams]
      supprimees = session[:lastparams] - params.keys
      logger.debug "[DEBUG] suppr: #{supprimees}"
    end
    session[:lastparams] = params.keys
    logger.debug "[DEBUG] last params: #{session[:lastparams]}"

    if params[:famille_id]
       @famille_id = params[:famille_id]
       @enfants = Enfant.find_all_by_famille_id(@famille_id)
    else
       @enfants = Enfant.where(id:params[:enfant_id])
    end

    @enfants.count.times { |i|
        @enfant = @enfants[i]
        #retourne le tarif
        @tarif = Facturation.best_tarif(@enfant)
	      date = Date.new(@year.to_i, @mois.to_i, 1)
        #logger.debug "Date:#{date} "

        # supprime les décochés
        if supprimees.any? 
           keys = supprimees.first.split(".")  
           d = Date.new(@year.to_i, @mois.to_i, keys.first.to_i)
           @p = Prestation.where(enfant_id:@enfant.id, date:d).first
           @p.update_attributes(keys.last => '0')
           logger.debug "[DEBUG] presta à suppr: #{@p.inspect}"  
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
            @prestation.garderieAM = '1' if params[:"#{day}.garderieAM"]
            @prestation.garderiePM = '1' if params[:"#{day}.garderiePM"]
            @prestation.centreAM = '1' if params[:"#{day}.centreAM"]
            @prestation.centrePM = '1' if params[:"#{day}.centrePM"]
            @prestation.etude = '1' if params[:etude] and ( date.wday != 3 and date.wday != 6 and date.wday != 0 and @vacances.empty?)
            @prestation.totalA = 0.00
            @prestation.save

            # calcul prestations type 1 ' Normale
            nbr_prestation = {'Repas' => 0,'GarderieAM' => 0,'GarderiePM' => 0, 'CentreAM' => 0, 'CentrePM' => 0, 'CentreAMPM' => 0, 'Etude' => 0, 'MntRepas' => 0,'MntGarderieAM' => 0,'MntGarderiePM' => 0, 'MntCentreAM' => 0, 'MntCentrePM' => 0, 'MntCentreAMPM' => 0, 'MntEtude' => 0 ,'JoursRepas' => "",'JoursGarderieAM' => "",'JoursGarderiePM' => "", 'JoursCentreAM' =>"", 'JoursCentrePM' => "", 'JoursCentreAMPM' => "", 'JoursEtude' => "",'PrixCentreAMPM' => 0, 'PrixCentreAM' => 0, 'PrixCentrePM' => 0}
            nbr_prestation = Facturation.calc_prestation(nbr_prestation, @prestation, @tarif, date)

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

    respond_to do |format|
       format.html
	     format.js
 	  end
  end


  def new_manual_calc_test
    if params[:famille_id]
       @famille_id = params[:famille_id]
       @enfants = Enfant.find_all_by_famille_id(@famille_id)
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
        logger.debug "!!! DATE : #{date} Type: #{type}"
        presta = Prestation.first_or_create(enfant_id:params[:enfant_id], date:date)
        logger.debug "!!! Presta : #{presta.inspect}"
      end  
    end
        
    respond_to do |format|
       format.html
       format.js
    end
  end

  def new_manual_classroom
	  @date = session[:date]
	  @classe = session[:classe]

    @kids_to_show=[]
	  @kids_to_show_presta=[]

	  @enfants = Enfant.find_all_by_classe(@classe, :joins =>:famille, :order => 'nom')
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
  	@date   = session[:date] 
  	@classe = session[:classe] 

  	@enfants = Enfant.find_all_by_classe(@classe, :joins =>:famille, :order => 'nom')

  	@enfants.each do |e|
  		if params[:"#{e.id}RepasAM"] or params[:"#{e.id}GarderieAM"] or params[:"#{e.id}GarderiePM"] or params[:"#{e.id}CentreAM"] or params[:"#{e.id}CentrePM"] then
  			@prestation = Prestation.find_or_create_by_date_and_enfant_id(@date.to_date.to_s(:en), e.id)
  		  @prestation.repas = params[:"#{e.id}RepasAM"] ? '1' : '0'
  		  @prestation.garderieAM = params[:"#{e.id}GarderieAM"] ? '1' : '0'
  		  @prestation.garderiePM = params[:"#{e.id}GarderiePM"] ? '1' : '0'
  		  @prestation.centreAM = params[:"#{e.id}CentreAM"] ? '1' : '0'
  		  @prestation.centrePM = params[:"#{e.id}CentrePM"] ? '1' : '0'
  			@prestation.save
  		end
  	end
    flash[:notice]="Prestations enregistrées..."
    redirect_to prestations_path
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

end
