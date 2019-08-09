# encoding: utf-8

class VacancesController < ApplicationController

  layout "standard"

  before_action :check, :except => ['index', 'new', 'create']

  def check
    unless Vacance.where("id = ? AND mairie_id = ?", params[:id], session[:mairie]).any?
       redirect_to :action => 'index'
    end
  end

  # GET /vacances
  # GET /vacances.xml
  def index
    @vacances = Vacance.where("mairie_id = ?",session[:mairie]).order(:debut)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @vacances }
    end
  end

  # GET /vacances/1
  # GET /vacances/1.xml
  def show
    @vacance = Vacance.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @vacance }
    end
  end

  # GET /vacances/new
  # GET /vacances/new.xml
  def new
    @vacance = Vacance.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @vacance }
    end
  end

  # GET /vacances/1/edit
  def edit
    @vacance = Vacance.find(params[:id])
  end

  # POST /vacances
  # POST /vacances.xml
  def create
    @vacance = Vacance.new(vacance_params)
    @vacance.mairie_id = session[:mairie]
    @vacance.log_changes(0, session[:user])

    respond_to do |format|
      if @vacance.save
        #flash[:notice] = 'Vacance was successfully created.'
        format.html { redirect_to(vacances_url) }
        format.xml  { render :xml => @vacance, :status => :created, :location => @vacance }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @vacance.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /vacances/1
  # PUT /vacances/1.xml
  def update
    @vacance = Vacance.find(params[:id])
    @vacance.attributes = vacance_params
    @vacance.log_changes(1, session[:user])

    respond_to do |format|
      if @vacance.save(validate:false)
        #flash[:notice] = 'Vacance was successfully updated.'
        format.html { redirect_to(vacances_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @vacance.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /vacances/1
  # DELETE /vacances/1.xml
  def destroy
    @vacance = Vacance.find(params[:id])
    @vacance.log_changes(3, session[:user])
    @vacance.destroy

    respond_to do |format|
      format.html { redirect_to(vacances_url) }
      format.xml  { head :ok }
    end
  end

  private
  # Never trust parameters from the scary internet, only allow the white list through.
    def vacance_params
      params.require(:vacance).permit(:nom,:debut,:fin,:mairie_id)
    end

end
