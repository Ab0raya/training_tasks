from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

users_db = {}

class User(BaseModel):
    email: str
    password: str

@app.post("/signup")
def sign_up(user: User):
    if user.email in users_db:
        raise HTTPException(status_code=400, detail="Email already registered")
    users_db[user.email] = user.password
    return {"message": "Account created successfully"}

@app.post("/login")
def login(user: User):
    if user.email not in users_db or users_db[user.email] != user.password:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    return {"message": "Logged in successfully"}

@app.get("/users")
def get_users():
    return {"users": [{"email": email} for email in users_db.keys()]}
