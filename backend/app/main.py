import os
from datetime import datetime
from typing import Optional
import mysql.connector
from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel, EmailStr

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Hello from FastAPI + Docker!"}

@app.get("/health")
def health():
    return {"status": "ok"}

class SignupRequest(BaseModel):
    name: str
    email: EmailStr
    password: str


class UpdateProfileRequest(BaseModel):
    email: EmailStr
    name: Optional[str] = None
    password: Optional[str] = None


class ProfileResponse(BaseModel):
    id: int
    name: str
    email: EmailStr
    created_at: datetime

@app.post("/signup")
def signup(req: SignupRequest):
    conn = None
    cur = None
    try:
        conn = mysql.connector.connect(
            host=os.getenv("DB_HOST", "db"),
            port=int(os.getenv("DB_PORT", "3306")),
            user=os.getenv("DB_USER", "app_user"),
            password=os.getenv("DB_PASSWORD", "app_pass"),
            database=os.getenv("DB_NAME", "app_db"),
        )
        cur = conn.cursor()

        cur.execute("SELECT id FROM users WHERE email=%s", (req.email,))
        if cur.fetchone():
            raise HTTPException(status_code=400, detail="Email already exists")

        cur.execute(
            "INSERT INTO users (name, email, password_hash) VALUES (%s, %s, %s)",
            (req.name, req.email, req.password),
        )
        conn.commit()

        return {"result": "ok"}

    except Exception as e:
        # 🔥 이 줄이 핵심
        print("SIGNUP ERROR >>>", repr(e))
        raise HTTPException(status_code=500, detail=str(e))

    finally:
        try:
            if cur is not None:
                cur.close()
            if conn is not None:
                conn.close()
        except Exception:
            pass


@app.get("/profile", response_model=ProfileResponse)
def get_profile(email: EmailStr = Query(...)):
    conn = None
    cur = None
    try:
        conn = mysql.connector.connect(
            host=os.getenv("DB_HOST", "db"),
            port=int(os.getenv("DB_PORT", "3306")),
            user=os.getenv("DB_USER", "app_user"),
            password=os.getenv("DB_PASSWORD", "app_pass"),
            database=os.getenv("DB_NAME", "app_db"),
        )
        cur = conn.cursor(dictionary=True)
        cur.execute(
            "SELECT id, name, email, created_at FROM users WHERE email=%s",
            (str(email),),
        )
        row = cur.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="User not found")
        return row
    except HTTPException:
        raise
    except Exception as e:
        print("PROFILE ERROR >>>", repr(e))
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        try:
            if cur is not None:
                cur.close()
            if conn is not None:
                conn.close()
        except Exception:
            pass


@app.put("/profile", response_model=ProfileResponse)
def update_profile(req: UpdateProfileRequest):
    if not req.name and not req.password:
        raise HTTPException(status_code=400, detail="Nothing to update")

    conn = None
    cur = None
    try:
        conn = mysql.connector.connect(
            host=os.getenv("DB_HOST", "db"),
            port=int(os.getenv("DB_PORT", "3306")),
            user=os.getenv("DB_USER", "app_user"),
            password=os.getenv("DB_PASSWORD", "app_pass"),
            database=os.getenv("DB_NAME", "app_db"),
        )
        cur = conn.cursor(dictionary=True)

        updates = []
        params = []
        if req.name:
            updates.append("name=%s")
            params.append(req.name)
        if req.password:
            updates.append("password_hash=%s")
            params.append(req.password)

        params.append(str(req.email))
        cur.execute(
            f"UPDATE users SET {', '.join(updates)} WHERE email=%s",
            tuple(params),
        )
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="User not found")

        conn.commit()

        cur.execute(
            "SELECT id, name, email, created_at FROM users WHERE email=%s",
            (str(req.email),),
        )
        row = cur.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="User not found")
        return row
    except HTTPException:
        raise
    except Exception as e:
        print("PROFILE UPDATE ERROR >>>", repr(e))
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        try:
            if cur is not None:
                cur.close()
            if conn is not None:
                conn.close()
        except Exception:
            pass
