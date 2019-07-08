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
