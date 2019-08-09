  # encoding: utf-8

class ApplicationController < ActionController::Base
  protect_from_forgery

  before_action :check_authentification

  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery  :secret => 'f17c8234007e8c8d92e577089d97e71f'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  #filter_parameter_logging :password

  def current_user
    @current_user ||= User.find(session[:user]) if session[:user]
  end
  helper_method :current_user

  def check_authentification
    unless session[:user]
       redirect_to :action => 'signin', :controller => "admin"
    end
  end

  def sort_param_in_session(sort,page)
    session[:order] ||= "ASC"
    if session[:sort] == sort
        #if session[:page] == page
           #session[:order] = (session[:order] == "ASC")?"DESC":"ASC"
        #end
    else
       session[:order] = "ASC"
    end
    session[:page] = page
    session[:sort] = sort
  end

  def format_mois(mois)
    lesmois = ['janvier','février','mars','avril','mai','juin','juillet','août','septembre','octobre','novembre','décembre']
    return lesmois[mois - 1]
  end

  def iphone_format?
    request.env["HTTP_USER_AGENT"] && request.env["HTTP_USER_AGENT"][/(Mobile\/.+Safari)/]
  end

  def get_etat_images
    @images = ["","yes.png","no.jpeg","orange.jpeg","cancel.jpeg","ok.jpeg","ok.jpeg","ok.jpeg"]
  end

end
