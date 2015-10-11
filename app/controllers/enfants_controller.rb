# encoding: utf-8

class EnfantsController < ApplicationController

  layout :determine_layout

  before_filter :check, :except => ['index', 'new', 'create', 'liste']

  skip_before_filter :check_authentification, only: :autocomplete

  def autocomplete
    familles = Famille.order(:nom).where("nom LIKE ? and  mairie_id = ?", "%#{params[:term]}%", session[:mairie])
    respond_to do |format|
      format.html
      format.json { render json: familles.map(&:nom) }
    end
  end

  def determine_layout
    if params[:action] == 'liste'
      "printer"
    else
      "standard"
    end
  end

  def check
    enfant_id = Enfant.find(params[:id]).famille_id
    unless Famille.where("id = ? AND mairie_id = ?", enfant_id, session[:mairie]).any?
      redirect_to :action => 'index'
    end
  rescue
    redirect_to :action => 'index'
  end

  # GET /enfants
  # GET /enfants.xml
  def index
    unless params[:sort].blank?
      sort = params[:sort]
      if session[:order_by] == sort
         sort = sort.split(" ").last == "DESC" ? sort.split(" ").first : sort + " DESC"   
      end  
      session[:order_by] = sort
    end
    order_by = (sort.blank?) ? "id DESC" : sort 

    mairie = Ville.find(session[:mairie])
    @classes = mairie.classrooms.order('nom').collect {|p| [ "#{p.nom} - #{p.referant}", p.id ] }

    @enfants = Enfant.where("familles.mairie_id = ?", session[:mairie]).joins(:famille).order('classe,familles.nom,prenom')

    unless params[:classe].blank?
      @enfants = @enfants.where(classe:params[:classe])
    end

    unless params[:search].blank?
      @enfants = @enfants.where("prenom like ? OR familles.nom like ?", "%#{params[:search]}%", "%#{params[:search]}%")
    end

    @enfants = @enfants.paginate(page:params[:page], per_page:18).order(order_by)    

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @enfants }
    end
  end

  def liste
    mairie = Ville.find(session[:mairie])
    @enfants = Enfant.where("familles.mairie_id = ?", session[:mairie]).joins(:famille)

    unless params[:classe].blank?
      @enfants = @enfants.where(classe:params[:classe])
    end

    unless params[:search].blank?
      @enfants = @enfants.where("prenom like ? OR familles.nom like ?", "%#{params[:search]}%", "%#{params[:search]}%")
    end
    @enfants = @enfants.order('classe,familles.nom,prenom')
  end

  # GET /enfants/1
  # GET /enfants/1.xml
  def show
    @enfant = Enfant.find(params[:id])
	  @classroom = Classroom.find_by_id(@enfant.classe)
    if params[:facturees] == 'on'
       @prestations = @enfant.prestations.facturees
    else
       @prestations = @enfant.prestations.afacturer		
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @enfant }
    end
  end

  # GET /enfants/new
  # GET /enfants/new.xml
  def new
    @enfant = Enfant.new
    @enfant.famille_id = params[:famille_id]
    @enfant.nomfamille = Famille.find(params[:famille_id]).nom.upcase
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @enfant }
    end
  end

  # GET /enfants/1/edit
  def edit
    @enfant = Enfant.find(params[:id])
  end

  # POST /enfants
  # POST /enfants.xml
  def create
    @enfant = Enfant.new(enfant_params)
    @enfant.log_changes(0, session[:user])

    respond_to do |format|
      if @enfant.save
        if @enfant.dateNaissance
            birthday = @enfant.dateNaissance.to_date
            @enfant.age = Date.today.year - birthday.year
            @enfant.log_changes(1, session[:user])
            @enfant.save
        end
        flash[:notice] = 'Fiche enfant ajoutée'
        format.html { redirect_to :controller => 'familles', :id => @enfant.famille_id, :action => 'show' }
        format.xml  { render :xml => @enfant, :status => :created, :location => @enfant }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @enfant.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /enfants/1
  # PUT /enfants/1.xml
  def update
    @enfant = Enfant.find(params[:id])
    @enfant.attributes = enfant_params
    @enfant.log_changes(1, session[:user])
    
    respond_to do |format|
      if @enfant.save(validate:false)
        if @enfant.dateNaissance
            birthday = @enfant.dateNaissance.to_date
            @enfant.age = Date.today.year - birthday.year
            @enfant.log_changes(1, session[:user])
            @enfant.save
        end
        flash[:notice] = 'Fiche enfant modifiée'
        format.html { redirect_to(@enfant) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @enfant.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /enfants/1
  # DELETE /enfants/1.xml
  def destroy
    @enfant = Enfant.find(params[:id])
    famille_id = @enfant.famille_id
    @enfant.log_changes(2, session[:user])
    @enfant.destroy

    respond_to do |format|
      format.html { redirect_to :controller => 'familles', :action => 'show', :id => famille_id }
      format.xml  { head :ok }
    end
  end

  private
  # Never trust parameters from the scary internet, only allow the white list through.
    def enfant_params
      params.require(:enfant).permit(:famille_id,:prenom,:age,:classe,:referant,:sansPorc,:allergies,:dateNaissance,:tarif_id,:habitudeGarderieAM,:habitudeGarderiePM,:nomfamille)
    end

end
