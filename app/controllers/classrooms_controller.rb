# encoding: utf-8

class ClassroomsController < ApplicationController

  layout "standard"

  before_action :check, :except => ['index', 'new', 'create']

  def check
    unless Classroom.where("id = ? AND mairie_id = ?", params[:id], session[:mairie]).any?
       redirect_to :action => 'index'
    end
  end

  # GET /classrooms
  # GET /classrooms.xml
  def index
    @classrooms = Classroom.where(mairie_id:session[:mairie]).order(:nom)
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @classrooms }
    end
  end

  # GET /classrooms/1
  # GET /classrooms/1.xml
  def show
    @classroom = Classroom.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @classroom }
    end
  end

  # GET /classrooms/new
  # GET /classrooms/new.xml
  def new
    @classroom = Classroom.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @classroom }
    end
  end

  # GET /classrooms/1/edit
  def edit
    @classroom = Classroom.find(params[:id])
  end

  # POST /classrooms
  # POST /classrooms.xml
  def create
    @classroom = Classroom.new(classroom_params)
    @classroom.mairie_id = session[:mairie]
    @classroom.log_changes(0, session[:user])

    respond_to do |format|
      if @classroom.save
        flash[:notice] = 'Classe ajoutée.'
        format.html { redirect_to(classrooms_url) }
        format.xml  { render :xml => @classroom, :status => :created, :location => @classroom }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @classroom.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /classrooms/1
  # PUT /classrooms/1.xml
  def update
    @classroom = Classroom.find(params[:id])
    @classroom.attributes = classroom_params
    @classroom.log_changes(1, session[:user])

    respond_to do |format|
      if @classroom.save(validate:false)
        flash[:notice] = 'Classe modifiée.'
        format.html { redirect_to(classrooms_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @classroom.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /classrooms/1
  # DELETE /classrooms/1.xml
  def destroy
    @classroom = Classroom.find(params[:id])
    @classroom.log_changes(2, session[:user])
    @classroom.destroy

    respond_to do |format|
      format.html { redirect_to(classrooms_url) }
      format.xml  { head :ok }
    end
  end

  private
  # Never trust parameters from the scary internet, only allow the white list through.
    def classroom_params
      params.require(:classroom).permit(:nom,:referant,:mairie_id)
    end

end
