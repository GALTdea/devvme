# Pagy initializer file
# Instance variables
# See https://ddnexus.github.io/pagy/docs/api/pagy#instance-variables
Pagy::DEFAULT[:limit] = 10           # items per page
Pagy::DEFAULT[:size]  = 9           # nav bar links

# Rails: it works by default
# Sinatra: you need to `include Pagy::Backend` in your code
