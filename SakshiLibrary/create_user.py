from app import app, db, User
from werkzeug.security import generate_password_hash

with app.app_context():
    # पासवर्ड को गुप्त (Secure) बना रहे हैं
    hashed_password = generate_password_hash('helper123', method='pbkdf2:sha256')
    
    # नया हेल्पर बना रहे हैं
    new_user = User(username='helper', password=hashed_password, role='helper')
    
    db.session.add(new_user)
    db.session.commit()
    print("✅ बधाई हो! Helper ID बन गई है।")