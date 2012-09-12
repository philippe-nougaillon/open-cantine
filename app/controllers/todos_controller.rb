# encoding: utf-8

class TodosController < ApplicationController

  layout 'standard'

  # GET /todos
  # GET /todos.xml
  def index
    @todos = Todo.find(:all, :order => "counter DESC")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @todos }
    end
  end

  # GET /todos/1
  # GET /todos/1.xml
  def show
    @todo = Todo.find(params[:id])

    ip = request.remote_ip
    session[:votants] ||= [] unless session[:votants]
     	
    unless session[:votants].include?(ip)
     	session[:votants].push(ip)
	@todo.counter += 1
	@todo.save	
	flash[:notice] = 'Merci pour votre vote'
    else
	flash[:warning] = 'Vous avez déjà voté.'
    end	

    respond_to do |format|
	format.html { redirect_to(todos_url) }
	format.xml  { render :xml => @todo, :status => :created, :location => @todo }
    end

  end

  # GET /todos/new
  # GET /todos/new.xml
  def new
    @todo = Todo.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @todo }
    end
  end

  # POST /todos
  # POST /todos.xml
  def create
    @todo = Todo.new(params[:todo])
    @todo.counter = 1	

    respond_to do |format|
      if @todo.save
        flash[:notice] = 'Souhait ajouté.'
        format.html { redirect_to(todos_url) }
        format.xml  { render :xml => @todo, :status => :created, :location => @todo }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @todo.errors, :status => :unprocessable_entity }
      end
    end
  end
  
end