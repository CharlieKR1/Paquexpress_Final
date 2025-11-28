import os
import shutil
import hashlib
from typing import List, Optional
from datetime import datetime
from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Depends
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String, DECIMAL, TIMESTAMP, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# 1. Configuración XAMPP y Carpetas
os.makedirs("evidencias", exist_ok=True) # Crea la carpeta automáticamente
DATABASE_URL = "mysql+pymysql://root:@localhost/db_paquexpress" # XAMPP sin contraseña

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()
app = FastAPI()

# 2. Archivos estáticos y Permisos
app.mount("/evidencias", StaticFiles(directory="evidencias"), name="evidencias")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# 3. Modelos BD
class Agente(Base):
    __tablename__ = "agentes"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50))
    password_hash = Column(String(255))
    nombre_completo = Column(String(100))

class Paquete(Base):
    __tablename__ = "paquetes"
    id = Column(Integer, primary_key=True, index=True)
    tracking_number = Column(String(20))
    direccion_destino = Column(String(255))
    destinatario = Column(String(100))
    latitud_destino = Column(DECIMAL(10, 8))
    longitud_destino = Column(DECIMAL(11, 8))
    estado = Column(String(20))
    agente_asignado_id = Column(Integer, ForeignKey("agentes.id"))
    foto_evidencia = Column(String(255))
    fecha_entrega = Column(TIMESTAMP)

Base.metadata.create_all(bind=engine)

# 4. Schemas y Funciones
class LoginRequest(BaseModel):
    username: str
    password: str

class PaqueteSchema(BaseModel):
    id: int
    tracking_number: str
    direccion_destino: str
    destinatario: str
    latitud_destino: float
    longitud_destino: float
    estado: str
    class Config:
        from_attributes = True

def get_db():
    db = SessionLocal()
    try: yield db
    finally: db.close()

def md5_hash(password: str) -> str:
    return hashlib.md5(password.encode()).hexdigest()

# 5. Endpoints Requeridos por el Caso Práctico
@app.post("/login/")
def login(data: LoginRequest, db=Depends(get_db)):
    user = db.query(Agente).filter(Agente.username == data.username).first()
    if not user or user.password_hash != md5_hash(data.password):
        raise HTTPException(status_code=400, detail="Credenciales incorrectas")
    return {"msg": "Login exitoso", "user_id": user.id}

@app.get("/paquetes/{agente_id}", response_model=List[PaqueteSchema])
def listar_paquetes(agente_id: int, db=Depends(get_db)):
    return db.query(Paquete).filter(Paquete.agente_asignado_id == agente_id).all()

@app.post("/entregar/")
async def entregar(paquete_id: int = Form(...), file: UploadFile = File(...), db=Depends(get_db)):
    paquete = db.query(Paquete).filter(Paquete.id == paquete_id).first()
    if not paquete: raise HTTPException(status_code=404)
    
    nombre = f"evidencias/{paquete.tracking_number}.jpg"
    with open(nombre, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    paquete.foto_evidencia = nombre
    paquete.estado = 'entregado'
    paquete.fecha_entrega = datetime.now()
    db.commit()
    return {"msg": "Entregado"}