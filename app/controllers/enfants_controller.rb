# encoding: utf-8

class EnfantsController < ApplicationController

  layout :determine_layout

  before_filter :check, :except => ['index', 'new', 'create', 'liste']

  def determine_layout
    if params[:action] == 'liste'
      "printer"
    else
      "standard"
    end
  end

  def check
    enfant_id = Enfant.find(params[:id]).famille_id
    unless Famille.find(:first, :conditions => [" id = ? AND mairie_id = ?", enfant_id, session[:mairie]])
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

    mairie = Ville.find(session[:mairie])
    @enfants = Enfant.search(params[:search], params[:page], params[:classe], session[:mairie], sort)
    @classes = mairie.classrooms.order('nom').collect {|p| [ "#{p.nom} - #{p.referant}", p.id ] }
    @classes.insert(0, '')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @enfants }
    end
  end

  def liste
    mairie = Ville.find(session[:mairie])
    @enfants = mairie.enfants.joins(:famille).order('classe,familles.nom,prenom')
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
    @enfant = Enfant.new(params[:enfant])
    respond_to do |format|
      if @enfant.save
         if @enfant.dateNaissance
            birthday = @enfant.dateNaissance.to_date
            @enfant.age = Date.today.year - birthday.year
         end
        @enfant.save
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

    respond_to do |format|
      if @enfant.update_attributes(params[:enfant])
        if @enfant.dateNaissance
            birthday = @enfant.dateNaissance.to_date
            @enfant.age = Date.today.year - birthday.year
        end
        @enfant.save
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
    @enfant.destroy

    respond_to do |format|
      format.html { redirect_to :controller => 'familles', :action => 'show', :id => famille_id }
      format.xml  { head :ok }
    end
  end

end
