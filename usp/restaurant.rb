class Restaurant
  def initialize(restaurant)
    @restaurant = restaurant
  end

  def method_missing(name, *args)
    if @restaurant.key? 
  end
end
