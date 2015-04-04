require 'prime'

from_int = client_row * 100000
to_int = (client_row + 1) * 100000
puts "Searching prime numbers from #{from_int} to #{to_int}"
results = []
from_int.upto(to_int) do |i|
  results << i if i.prime?
end
results
