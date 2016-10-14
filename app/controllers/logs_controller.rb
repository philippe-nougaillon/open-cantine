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

    unless params[:date].blank?
      date = Date.parse(params[:date], "dd.mm.YYYY")

      @logs = @logs.where("created_at like ?", "%#{date.to_s(:en)}%")
    end

    @logs = @logs.paginate(page:params[:page]).order('created_at DESC')

  end

end
