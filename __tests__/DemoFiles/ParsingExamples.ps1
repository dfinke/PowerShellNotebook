# # This is file is an example of what _should_ happen when converting a .PS1 file to a .IPYNB file.
ps | select -first 10

# Get first 10 services
gsv | select -first 10

# Create a function
function SayHello($p) {"Hello $p"}

# Use the function
SayHello World