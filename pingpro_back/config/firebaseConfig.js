// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyDYdov4nfpdCZY757UU46JWvImBw_B1-OY",
  authDomain: "pingpro-n0622c.firebaseapp.com",
  projectId: "pingpro-n0622c",
  storageBucket: "pingpro-n0622c.firebasestorage.app",
  messagingSenderId: "295247869938",
  appId: "1:295247869938:web:8806afe17a0cfb3a405d6b",
  measurementId: "G-WFGDKM922Z"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);