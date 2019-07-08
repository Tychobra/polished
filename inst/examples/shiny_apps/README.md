# Getting Started

```
# terminal
firebase init
# check that you want to use firestore and functions
# use JavaScript and no eslint when prompted
# Do you want to install dependencies with npm now? Yes
```

Install Firebase functions dependencies 
```
# terminal

npm install --save firebase-admin firebase-functions
```

### copy the firebase.rules from another app and then 


```
# terminal
firebase deploy --only firestore:rules


firebase deploy --only functions
```

### deploy iframe to Firebase hosting

1. update "firebase.json" for the iframe you are going to host.  See "firebase.json" in this
directory for an example.
2. If this is the first site for this firebase project, set up your new hosting name with the
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
