# encoding: utf-8

class TarifsController < ApplicationController

  layout "standard"
  before_action :check, :except => ['index', 'new', 'create']

  def check
    unless Tarif.where("id = ? AND mairie_id = ?", params[:id], session[:mairie]).any?
       redirect_to :action => 'index'
    end
  end

  # GET /tarifs
  # GET /tarifs.xml
  def index
    @tarifs = Tarif.where(mairie_id:session[:mairie]).order(:memo)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @tarifs }
    end
  end

  # GET /tarifs/1
  # GET /tarifs/1.xml
  def show
    @tarif = Tarif.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @tarif }
    end
  end

  # GET /tarifs/new
  # GET /tarifs/new.xml
  def new
    @tarif = Tarif.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @tarif }
    end
  end

  # GET /tarifs/1/edit
  def edit
    @tarif = Tarif.find(params[:id])
  end

  # POST /tarifs
  # POST /tarifs.xml
  def create
    @tarif = Tarif.new(tarif_params)
    @tarif.mairie_id = session[:mairie]
    @tarif.log_changes(0, session[:user])

    respond_to do |format|
      if @tarif.save
        flash[:notice] = ''
        format.html { redirect_to(tarifs_url) }
        format.xml  { render :xml => @tarif, :status => :created, :location => @tarif }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @tarif.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /tarifs/1
  # PUT /tarifs/1.xml
  def update
    @tarif = Tarif.find(params[:id])
    @tarif.attributes = tarif_params
    @tarif.log_changes(1, session[:user])

    respond_to do |format|
      if @tarif.save(validate:false)
        flash[:notice] = 'Tarifs modifiés.'
        format.html { redirect_to(tarifs_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @tarif.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /tarifs/1
  # DELETE /tarifs/1.xml
  def destroy
    @tarif = Tarif.find(params[:id])
    @tarif.log_changes(2, session[:user])
    @tarif.destroy

    respond_to do |format|
      format.html { redirect_to(tarifs_url) }
      format.xml  { head :ok }
    end
  end

  private
  # Never trust parameters from the scary internet, only allow the white list through.
    def tarif_params
      params.require(:tarif).permit(:RepasP,:GarderieAMP,:GarderiePMP,:CentreAMP,:CentrePMP,:Etude,:CentreAMPMP,:mairie_id,:type_id,:memo)
    end
  
end
