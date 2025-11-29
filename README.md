# Sistema de Entregas Paquexpress S.A. de C.V.

Este proyecto es una solución integral para la logística y distribución de paquetes, desarrollada para mejorar la trazabilidad y seguridad en el proceso de entrega en campo

## Descripción del Proyecto
La aplicación permite a los agentes de entrega seleccionar paquetes asignados, visualizar su destino en un mapa y registrar la entrega mediante evidencia fotográfica y captura de ubicación GPS[cite: 5, 6, 7, 8].

### Características Principales
* **Seguridad:** Inicio de sesión con validación de credenciales y encriptación de contraseñas[cite: 12, 13].
* **Geolocalización:** Visualización de la ruta y captura de coordenadas al momento de la entrega[cite: 14].
* **Evidencia:** Captura y subida de fotografías como prueba de entrega[cite: 7].
* **Tecnología:** Stack tecnológico moderno y escalable[cite: 15].

## Tecnologías Utilizadas
* **Frontend:** Flutter (Dart) - Aplicación Móvil/Web.
* **Backend:** FastAPI (Python) - API REST.
* **Base de Datos:** MySQL - Almacenamiento relacional.
* **Mapas:** OpenStreetMap & flutter_map.

## Instrucciones de Instalación

### 1. Base de Datos
1.  Tener instalado XAMPP o MySQL Server.
2.  Importar el archivo `database.sql` incluido en este repositorio mediante phpMyAdmin o Workbench.
3.  Esto creará la base de datos `db_paquexpress` y el usuario admin (`admin` / `123`).

### 2. (API)
1.  Navegar a la carpeta `/backend`.
2.  Instalar dependencias:
    ```bash
    pip install fastapi uvicorn sqlalchemy pymysql python-multipart
    ```
3.  Ejecutar el servidor:
    ```bash
    uvicorn main:app --reload --host 0.0.0.0
    ```

### 3. Aplicación Móvil
1.  Navegar a la carpeta `/app_movil`.
2.  Instalar dependencias:
    ```bash
    flutter pub get
    ```
3.  Ejecutar la aplicación (asegúrate de que la API esté corriendo):
    ```bash
    flutter run
    ```
    *Nota: Si ejecutas en Web, usar Chrome. Si es en Android, asegurar que el emulador tenga conexión.*

## 👤 Autor
[Carlos Augusto Rodriguez Alvarado]
Evaluación de la Unidad 3 - Desarrollo de Aplicaciones Móviles.