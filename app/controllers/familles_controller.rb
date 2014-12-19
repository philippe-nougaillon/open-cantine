# encoding: utf-8

class FamillesController < ApplicationController

  #autocomplete :famille, :nom, :extra_data => [:cp, :ville]
  
  layout :determine_layout

  before_filter :check, :except => ['index', 'new', 'create', 'balance', 'listing', 'autocomplete']

  skip_before_filter :check_authentification, only: :autocomplete

  def autocomplete
    familles = Famille.order(:nom).where("nom LIKE ? and  mairie_id = ?", "%#{params[:term]}%", session[:mairie])
    respond_to do |format|
      format.html
      format.json { render json: familles.map(&:nom) }
    end
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
  		# if params.has_key?('famille_id') and !params[:famille_id].empty?
  		#    @famille = Famille.find(params[:famille_id])
  		#    format.html { redirect_to(@famille) }

    unless params[:sort].blank?
      sort = params[:sort]
      if session[:order_by] == sort
         sort = sort.split(" ").last == "DESC" ? sort.split(" ").first : sort + " DESC"   
      end  
      session[:order_by] = sort
    end

    @familles = Famille.search(params[:nom], params[:page], session[:mairie], sort)
    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml => Famille.find_all_by_mairie_id(session[:mairie]).to_xml( :include => [:enfants,:prestations]) }
      format.js
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
    @famille.log_changes(0, session[:user])

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
    @famille.attributes = params[:famille]
    @famille.log_changes(1, session[:user])

    respond_to do |format|
      if @famille.save(validate:false)
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
    @famille.log_changes(2, session[:user])
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
    @factures = Facture.find_all_by_famille_id(@famille.id)
    @paiements = Paiement.find_all_by_famille_id(@famille.id)

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
  	  format.pdf do
   		    pdf = RelevePdf.new(session[:mairie], @famille, @releve, view_context)
          send_data pdf.render, :type => "application/pdf", 
  				  :filename => "Relevé famille '#{@famille.nom}' au #{Date.today.strftime("%d/%m/%Y")}.pdf"
      end   
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

class RelevePdf < Prawn::Document

  include ActionView::Helpers::NumberHelper
     
  def initialize(mairie, famille, releve, view)
    super()
	@mairie = Ville.find(mairie)
	@famille = famille

	if @mairie.id = 2
		logopath =  "#{Rails.root}/public/images/school.png"
	    image logopath, :height => 40
		move_down 10
	else
		move_down 20
	end

    text @mairie.nom,  :size => 17, :style => :bold
	move_down 10

	text @mairie.adr,  :size => 14
	text "#{@mairie.cp} #{@mairie.ville}", :size => 14
	move_down 20

	text @mairie.readable_tel, :size => 12
	text @mairie.email, :size => 12
	move_down 30

	text "#{@famille.civilité} #{@famille.nom.to_s.upcase}", :indent_paragraphs => 300, :size => 14, :style =>  :bold
	move_down 10

	text @famille.adresse, :indent_paragraphs => 300, :size => 12
	text "#{@famille.cp} #{@famille.ville}", :indent_paragraphs => 300, :size => 12

	move_down 30
	text "#{@mairie.ville}, le #{Date.today.to_date.to_s(:fr)}", :indent_paragraphs => 300, :size => 14

	move_down 30
	text "Relevé de compte", :size => 16

	@solde  = 0 
	@debit  = 0
	@credit = 0
	@mnt_debit = 0
	@mnt_credit = 0
	
	items = [["Date","Type","Référence","Débit","Crédit","Solde"]] 
	items += releve.map do |item|
		@montant = item[:mnt] || 0
	    if item[:type] == "Facture"
			@solde -= @montant
			@debit += @montant
			@mnt_debit = @montant
			@mnt_credit = 0
		else
			@solde += @montant
			@credit += @montant
			@mnt_debit = 0
			@mnt_credit = @montant
		end
		[
 		item[:date].to_s(:fr),
        item[:type],
        item[:ref],
		number_to_currency(@mnt_debit ,:locale => 'fr'),
		number_to_currency(@mnt_credit,:locale => 'fr'),
		number_to_currency(@solde, :locale => 'fr')
		]
	end

	items += [[Date.today.to_s(:fr),"Solde à ce jour","", number_to_currency(@debit, :locale => 'fr'), number_to_currency(@credit, :locale => 'fr'), number_to_currency(@solde, :locale => 'fr')]]

	move_down 50

	table(items, :row_colors => ["F0F0F0", "FFFFCC"], :width => 550) do
		self.header = true
		columns(0).align = :left
		columns(0).font_style = :bold
		columns(0).size = 10

		columns(1).align = :left
		columns(1).size = 10

		columns(2).align = :left
		columns(2).size = 10

		columns(3).align = :right
		columns(3).width = 70
		columns(3).size = 10
		
		columns(4).align = :right
		columns(4).width = 70
		columns(4).size = 10
		
		columns(5).align = :right
		columns(5).width = 70
		columns(5).size = 10
		columns(5).font_style = :bold
	end
	move_down 20
	
  end

end

