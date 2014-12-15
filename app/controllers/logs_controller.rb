class LogsController < ApplicationController

  layout 'standard'

  # GET /logs
  # GET /logs.json
  def index

    unless params[:user_id].blank?
      user = User.find(params[:user_id])
      @logs = user.logs    
    else
      user = User.find(session[:user])
      @logs = user.ville.logs
    end

    unless params[:search].blank?
      @logs = @logs.where("quoi like ? OR msg like ?", "%#{params[:search]}%", "%#{params[:search]}%")          
    end

    @logs = @logs.paginate(page:params[:page]).order('created_at DESC')

    respond_to do |format|
      format.html # index.html.erb
    end
  end

end
