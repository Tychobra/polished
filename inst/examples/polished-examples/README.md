# Getting Started

```
# terminal
npm install -g firebase-tools

firebase init
# check that you want to use firestore and functions
# use JavaScript 
# do not use eslint when prompted
# Do you want to install dependencies with npm now? Yes
```

Install Firebase functions dependencies 
```
# terminal
cd functions
npm install --save firebase-admin firebase-functions
```

### copy the firebase.rules from another app and then 


```
# terminal
firebase deploy --only firestore:rules


firebase deploy --only functions
```

Go to the Shiny app and copy the Firebase configuration into the "config.yml"


### deploy iframe to Firebase hosting

1. update "firebase.json" hosting configuration:
```
# R
polished::write_firebase_hosting("auth_custom")
```

2. create the iframe for the new site

```
# R

polished::write_firebase_hosting_html("auth_custom")
```


3. If this is the first site for this firebase project, set up your new hosting name with the
defualt firebase hosting site.  e.g.

```
# terminal
firebase target:apply hosting auth_custom tychobraauth
```

3. make sure the app is deployed to 

4.  Deploy iframe to Firebase hosting

```
# terminal
firebase deploy --only hosting:auth_custom
```
