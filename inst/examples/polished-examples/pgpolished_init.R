library(pgpolished)


# TODO: function to set up database "polished" schema


write_firebase_functions()

system("firebase deploy --only functions")
