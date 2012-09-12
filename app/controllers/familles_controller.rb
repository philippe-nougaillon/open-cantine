# encoding: utf-8

class FamillesController < ApplicationController

  #in_place_edit_for :famille, :memo 

  autocomplete :famille, :nom, :extra_data => [:cp, :ville]
  
  layout :determine_layout

  before_filter :check, :except => ['index', 'new', 'create', 'balance', 'listing', 'autocomplete_famille_nom']

  def get_autocomplete_items(parameters)
    super(parameters).where(:mairie_id => session[:mairie])
  end


  def determine_layout
    if params[:action] == 'listing'
      "printer"
    else
      "standard"
    end
  end
  
  def check
    unless Famille.find(:first, :conditions =>  [" id = ? AND mairie_id = ?", params[:id], session[:mairie]])
       redirect_to :action => 'index'
    end
  end

  # GET /familles
  # GET /familles.xml
  def index
    respond_to do |format|
		if params.has_key?('famille_id') and !params[:famille_id].empty?
		   @famille = Famille.find(params[:famille_id])
		   format.html { redirect_to(@famille) }
		else
           @familles = Famille.search(params[:nom], params[:page], session[:mairie], params[:sort])
	       format.html # index.html.erb
      	   format.xml { render :xml => Famille.find_all_by_mairie_id(session[:mairie]).to_xml( :include => [:enfants,:prestations]) }
      	   format.js
		end
     end
  end

  # GET /familles/1
  # GET /familles/1.xml
  def show
  
    @famille = Famille.find(params[:id])
    @sumP  = @famille.factures.sum('montant')
    @sumIn = @famille.paiements.sum('montant')
    @solde = @sumIn - @sumP 
    @facture = @famille.factures.last
 
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @famille }
    end
  end

  # GET /familles/new
  # GET /familles/new.xml
  def new
    @famille = Famille.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @famille }
    end
  end

  # GET /familles/1/edit
  def edit
    @famille = Famille.find(params[:id])
  end

  # POST /familles
  # POST /familles.xml
  def create
    @famille = Famille.new(params[:famille])
    @famille.mairie_id = session[:mairie]

    respond_to do |format|
      if @famille.save
        flash[:notice] = 'Famille créée'
        format.html { redirect_to(@famille) }
        format.xml  { render :xml => @famille, :status => :created, :location => @famille }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @famille.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /familles/1
  # PUT /familles/1.xml
  def update
    @famille = Famille.find(params[:id])

    respond_to do |format|
      if @famille.update_attributes(params[:famille])
        flash[:notice] = 'Famille modifiée'

        format.html { redirect_to(@famille) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @famille.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /familles/1
  # DELETE /familles/1.xml
  def destroy
    @famille = Famille.find(params[:id])
    @famille.destroy

    respond_to do |format|
      format.html { redirect_to(familles_url) }
      format.xml  { head :ok }
    end
  end

  def balance
    @releve = []
    @solde = 0.00
    @debit = 0.00
    @credit = 0.00
    @famille = Famille.find(params[:id])
    @factures = Facture.find_all_by_famille_id(params[:id])
    @paiements = Paiement.find_all_by_famille_id(params[:id])

    for f in @factures
      balance = { :date => f.date.to_date, :type => "Facture", :ref => f.ref, :mnt => f.montant, :id => f.id }
      @releve << balance
    end

    for p in @paiements
      balance = { :date => p.date.to_date, :type => "Paiement", :ref => p.ref, :mnt => p.montant, :id => p.id }
      @releve << balance
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @releve }
    end
  end

  def listing
	@familles = Famille.find_all_by_mairie_id(session[:mairie], :order => "nom")
	respond_to do |format|
	      format.html 
      	      format.xml  { render :xml => @familles }
    	end
  end


end