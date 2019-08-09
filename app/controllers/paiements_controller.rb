# encoding: utf-8
require 'csv'

class PaiementsController < ApplicationController

  before_action :check, :except => ['index', 'new', 'create','listing','majdateremise']
  layout :determine_layout

  def check
    unless Paiement.where("id = ? AND mairie_id = ?", params[:id], session[:mairie]).any?
       redirect_to :action => 'index'
    end
  end

  def determine_layout
    if params[:action] == 'print' or params[:action] == 'listing'
      "printer"
    else
      "standard"
    end
  end
  
  # GET /paiements
  # GET /paiements.xml
  def index
     unless params[:sort].blank?
      sort = params[:sort]
      if session[:order_by] == sort
         sort = sort.split(" ").last == "DESC" ? sort.split(" ").first : sort + " DESC"   
      end  
      session[:order_by] = sort
    end

    @paiements = Paiement.where(mairie_id:session[:mairie]).joins(:famille)

    if params[:famille_id]
        @paiements = @paiements.where(famille_id:params[:famille_id])
    end  

    unless params[:search].blank?
        @paiements = @paiements.where("ref like ? or familles.nom like ? OR chequenum = ? ", "%#{params[:search]}%", "%#{params[:search]}%", params[:search])
    end
        
    order_by = (sort.blank?) ? "id DESC" : sort 
    @paiements = @paiements.paginate(per_page:18, page:params[:page]).order(order_by)
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @paiements }
	    format.xls  { @paiements = Paiement.where(mairie_id:session[:mairie]) }
    end
  end

  def listing
    @paiements = Paiement.where("remise is null AND typepaiement = 'CHEQUE' AND typepaiement = 'CHEQUE' AND mairie_id = ?", session[:mairie])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @paiements }
    end
  end

  def majdateremise
    @paiements = Paiement.where("remise is null AND typepaiement = 'CHEQUE' AND mairie_id = ?",session[:mairie])
    
    for p in @paiements
      p.remise = Date.today.to_s(:fr)
      p.save
    end

    respond_to do |format|
          flash[:notice] = 'Paiements mis à jour...'
          format.html { redirect_to :action => 'index' }
    end
  end

  # GET /paiements/1
  # GET /paiements/1.xml
  def show
    @paiement = Paiement.find(params[:id])
    @factures = Facture.where(mairie_id:session[:mairie])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @paiement }
    end
  end

  def print
    @paiement = Paiement.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @paiement }
    end
  end

  # GET /paiements/new
  # GET /paiements/new.xml
  def new
    @paiement = Paiement.new
    @paiement.famille_id = params[:famille_id]
    @paiement.date = Date.today.to_s(:fr)
    @factures = Facture.where("famille_id = ? AND mairie_id = ?", @paiement.famille_id, session[:mairie]).order('id DESC')

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @paiement }
    end
  end

  # GET /paiements/1/edit
  def edit
    @paiement = Paiement.find(params[:id])
    @factures = Facture.where("famille_id = ? AND mairie_id = ?", @paiement.famille_id, session[:mairie]).order('id DESC')
  end

  # POST /paiements
  # POST /paiements.xml
  def create
    @paiement = Paiement.new(paiement_params)
    @paiement.mairie_id = session[:mairie]

    if @paiement.montant.to_f == 0.0	
       if @paiement.montantCantine.to_f > 0.0 and @paiement.montantGarderie.to_f == 0.0	 
          @paiement.montant = @paiement.montantCantine
       end

       if @paiement.montantGarderie.to_f > 0.0 and @paiement.montantCantine.to_f == 0.0 	 
          @paiement.montant = @paiement.montantGarderie
       end
    else
       if @paiement.montantCantine.to_f > 0.0 and @paiement.montantGarderie.to_f == 0.0 	 
          @paiement.montantGarderie = @paiement.montant.to_f - @paiement.montantCantine.to_f
       end
       if @paiement.montantGarderie.to_f > 0.0 and @paiement.montantCantine.to_f == 0.0 	 
          @paiement.montantCantine = @paiement.montant.to_f - @paiement.montantGarderie.to_f
       end
    end		

    respond_to do |format|
      @paiement.log_changes(0, session[:user])
      if @paiement.save
        flash[:notice] = 'Paiement ajouté.'
        format.html { redirect_to :controller => 'familles', :action => 'show', :id => @paiement.famille_id }
        format.xml  { render :xml => @paiement, :status => :created, :location => @paiement }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @paiement.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /paiements/1
  # PUT /paiements/1.xml
  def update
    @paiement = Paiement.find(params[:id])
    #@factures = Facture.find(:all, :conditions =>  ["mairie_id = ?", session[:mairie]])
    @paiement.attributes = paiement_params
    @paiement.log_changes(1, session[:user])

    respond_to do |format|
      if @paiement.save(validate:false)
        flash[:notice] = 'Paiement modifié.'
        format.html { redirect_to :action => 'index' }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @paiement.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /paiements/1
  # DELETE /paiements/1.xml
  def destroy
    @paiement = Paiement.find(params[:id])
    @paiement.log_changes(2, session[:user])
    @paiement.destroy

    respond_to do |format|
      format.html { redirect_to(paiements_url) }
      format.xml  { head :ok }
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def paiement_params
      params.require(:paiement).permit(:date,:typepaiement,:ref,:banque,:montant,:famille_id,:mairie_id,:montantGarderie,:montantCantine,:remise,:chequenum,:memo,:facture_id)
    end   

end
