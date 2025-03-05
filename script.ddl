CREATE TABLE ZOLNIERZE (
    PESEL NUMBER(11) PRIMARY KEY,
    IMIE VARCHAR2(20 BYTE),
    NAZWISKO VARCHAR2(20 BYTE),
    WZROST NUMBER(3),
    GRUPA_KRW VARCHAR2(10 BYTE),
    ROZPOCZECIE_SLUZBY DATE,
    STOPIEN VARCHAR2(50 BYTE),
    PESEL_DOWODCY NUMBER(11) NULL,
    CONSTRAINT FK_STOPIEN FOREIGN KEY (STOPIEN) REFERENCES STOPNIE(NAZWA_STOPNIA),
    CONSTRAINT FK_DOWODCA FOREIGN KEY (PESEL_DOWODCY) REFERENCES ZOLNIERZE(PESEL)
);

CREATE TABLE STOPNIE (
    NAZWA_STOPNIA VARCHAR2(50 BYTE) PRIMARY KEY
);

CREATE TABLE POLIGONY (
    ID_POLIGONU NUMBER PRIMARY KEY,
    NAZWA VARCHAR2(80 BYTE) UNIQUE,
    LOKALIZACJA VARCHAR2(80 BYTE),
    CZYNY CHAR(3)
);

CREATE TABLE ZOLNIERZE_POLIGONY (
    PESEL_ZOLNIERZA NUMBER(11),
    ID_POLIGONU NUMBER,
    PRIMARY KEY (PESEL_ZOLNIERZA, ID_POLIGONU),
    FOREIGN KEY (PESEL_ZOLNIERZA) REFERENCES ZOLNIERZE(PESEL),
    FOREIGN KEY (ID_POLIGONU) REFERENCES POLIGONY(ID_POLIGONU)
);

CREATE TABLE MISJE (
    ID_MISJI NUMBER PRIMARY KEY,
    NAZWA VARCHAR2(100 BYTE) UNIQUE,
    LICZBA_ZOLNIERZY NUMBER,
    LICZBA_AMUNICJI NUMBER
);

CREATE TABLE ZOLNIERZE_MISJE (
    PESEL_ZOLNIERZA NUMBER(11),
    ID_MISJI NUMBER,
    PRIMARY KEY (PESEL_ZOLNIERZA, ID_MISJI),
    FOREIGN KEY (PESEL_ZOLNIERZA) REFERENCES ZOLNIERZE(PESEL),
    FOREIGN KEY (ID_MISJI) REFERENCES MISJE(ID_MISJI)
);

CREATE TABLE OPERACJE (
    NAZWA_OPERACJI VARCHAR2(100 BYTE) PRIMARY KEY,
    ID_MISJI NUMBER,
    FOREIGN KEY (ID_MISJI) REFERENCES MISJE(ID_MISJI)
);

CREATE TABLE TYPY_POJAZDU (
    NAZWA VARCHAR2(30 BYTE) PRIMARY KEY
);

CREATE TABLE POJAZDY (
    ID_POJAZDU NUMBER PRIMARY KEY,
    MODEL VARCHAR2(80 BYTE) UNIQUE,
    POJEMNOSC_ZBIORNIKA_W_LITRACH NUMBER,
    PRZEBIEG_W_KM NUMBER,
    TYP_POJAZDU VARCHAR2(30 BYTE),
    FOREIGN KEY (TYP_POJAZDU) REFERENCES TYPY_POJAZDU(NAZWA)
);

CREATE TABLE MISJE_POJAZDY (
    ID_MISJI NUMBER,
    ID_POJAZDU NUMBER,
    PRIMARY KEY (ID_MISJI, ID_POJAZDU),
    FOREIGN KEY (ID_MISJI) REFERENCES MISJE(ID_MISJI),
    FOREIGN KEY (ID_POJAZDU) REFERENCES POJAZDY(ID_POJAZDU)
);

CREATE TABLE BRON (
    ID_BRONI NUMBER PRIMARY KEY,
    MODEL VARCHAR2(80 BYTE) UNIQUE,
    KALIBER_MM NUMBER(10),
    DLUGOSC_LUFY_MM NUMBER(3),
    LICZBA_MAGAZYNIKOW NUMBER(1),
    WAGA_W_KG NUMBER(4),
    NAZWA_TYPU VARCHAR2(30 BYTE) UNIQUE,
    NAZWA_AMUNICJI VARCHAR2(80 BYTE),
    FOREIGN KEY (NAZWA_TYPU) REFERENCES TYPY_BRONI(NAZWA),
    FOREIGN KEY (NAZWA_AMUNICJI) REFERENCES AMUNICJA(NAZWA)
);

CREATE TABLE TYPY_BRONI (
    NAZWA VARCHAR2(30 BYTE) PRIMARY KEY
);


CREATE TABLE ZOLNIERZE_BRON (
    PESEL_ZOLNIERZA NUMBER(11),
    ID_BRONI NUMBER,
    PRIMARY KEY (PESEL_ZOLNIERZA, ID_BRONI),
    FOREIGN KEY (PESEL_ZOLNIERZA) REFERENCES ZOLNIERZE(PESEL),
    FOREIGN KEY (ID_BRONI) REFERENCES BRON(ID_BRONI)
);

CREATE TABLE AMUNICJA (
    NAZWA VARCHAR2(80 BYTE) PRIMARY KEY,
    DLUGOSC_NABOJU_W_MM NUMBER(3),
    LICZBA_W_MAGAZYNIE NUMBER
);




create or replace trigger TRG_ZOLNIERZE_VALIDACJE
BEFORE INSERT OR UPDATE ON ZOLNIERZE
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
    V_COUNT NUMBER;
BEGIN
    IF :NEW.PESEL IS NOT NULL THEN
        BEGIN
            SELECT COUNT(*)
            INTO V_COUNT
            FROM ZOLNIERZE
            WHERE PESEL = :NEW.PESEL AND (:NEW.PESEL != :OLD.PESEL OR :OLD.PESEL IS NULL);

            IF V_COUNT > 0 THEN
                RAISE_APPLICATION_ERROR(-20007, 'Taki pesel już istnieje.');
            END IF;
        END;
    END IF;

    IF LENGTH(TO_CHAR(:NEW.PESEL)) != 11 OR REGEXP_LIKE(:NEW.PESEL, '[^0-9]') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Pesel musi składać się dokładnie z 11 cyfr.');
    END IF;

    IF :NEW.WZROST IS NULL OR :NEW.WZROST < 150 OR :NEW.WZROST > 220 OR REGEXP_LIKE(TO_CHAR(:NEW.WZROST), '[^0-9]') THEN
        RAISE_APPLICATION_ERROR(-20002, 'Wzrost żołnierza musi być liczbą w zakresie od 150 do 220 cm.');
    END IF;

    IF :NEW.ROZPOCZECIE_SLUZBY > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20003, 'Data rozpoczęcia służby nie może być większa niż dzisiejsza data.');
    END IF;

    IF :NEW.IMIE IS NULL OR :NEW.NAZWISKO IS NULL OR :NEW.WZROST IS NULL OR
       :NEW.GRUPA_KRW IS NULL OR :NEW.ROZPOCZECIE_SLUZBY IS NULL OR :NEW.STOPIEN IS NULL THEN
        RAISE_APPLICATION_ERROR(-20004, 'Wszystkie dane żołnierza muszą być uzupełnione.');
    END IF;

    IF REGEXP_LIKE(:NEW.IMIE, '[^A-Za-z]') THEN
        RAISE_APPLICATION_ERROR(-20005, 'Imię musi zawierać tylko litery.');
    END IF;

    IF REGEXP_LIKE(:NEW.NAZWISKO, '[^A-Za-z]') THEN
        RAISE_APPLICATION_ERROR(-20006, 'Nazwisko musi zawierać tylko litery.');
    END IF;

    COMMIT;
END;


create or replace TRIGGER TRG_ZOLNIERZE_POLIGONY_WALIDACJE
BEFORE INSERT OR UPDATE ON ZOLNIERZE_POLIGONY
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    IF :NEW.PESEL_ZOLNIERZA IS NULL OR :NEW.ID_POLIGONU IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Wszystkie pola muszą być wypełnione.');
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM ZOLNIERZE_POLIGONY
    WHERE PESEL_ZOLNIERZA = :NEW.PESEL_ZOLNIERZA
    AND ID_POLIGONU = :NEW.ID_POLIGONU;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Taka kombinacja żołnierza i poligonu już istnieje.');
    END IF;
END;
/


create or replace TRIGGER TRG_ZOLNIERZE_MISJE_WALIDACJE
BEFORE INSERT OR UPDATE ON ZOLNIERZE_MISJE
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    IF :NEW.PESEL_ZOLNIERZA IS NULL OR :NEW.ID_MISJI IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Wszystkie dane muszą być wypełnione.');
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM ZOLNIERZE_MISJE
    WHERE PESEL_ZOLNIERZA = :NEW.PESEL_ZOLNIERZA
    AND ID_MISJI = :NEW.ID_MISJI;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Taka kombinacja żołnierza i misji już istnieje.');
    END IF;
END;
/


create or replace TRIGGER TRG_ZOLNIERZE_BRON_WALIDACJE
BEFORE INSERT OR UPDATE ON ZOLNIERZE_BRON
FOR EACH ROW
BEGIN
    IF :NEW.PESEL_ZOLNIERZA IS NULL OR :NEW.ID_BRONI IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Wszystkie dane muszą być wypełnione.');
    END IF;

    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM ZOLNIERZE_BRON
        WHERE PESEL_ZOLNIERZA = :NEW.PESEL_ZOLNIERZA
        AND ID_BRONI = :NEW.ID_BRONI
        AND (:NEW.PESEL_ZOLNIERZA != :OLD.PESEL_ZOLNIERZA OR :NEW.ID_BRONI != :OLD.ID_BRONI OR :OLD.PESEL_ZOLNIERZA IS NULL OR :OLD.ID_BRONI IS NULL);

        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Taka kombinacja pesela i id broni już istnieje.');
        END IF;
    END;
END;
/


create or replace TRIGGER TRG_TYPY_POJAZDU_WALIDACJE
BEFORE INSERT OR UPDATE ON TYPY_POJAZDU
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    IF :NEW.NAZWA IS NULL OR TRIM(:NEW.NAZWA) = '' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Wartość nazwy typu pojazdu nie może być pusta.');
    END IF;

    IF NOT REGEXP_LIKE(:NEW.NAZWA, '^[A-Za-ząćęłńóśżźĄĆĘŁŃÓŚŻŹ]+$') THEN
        RAISE_APPLICATION_ERROR(-20002, 'Nazwa typu pojazdu musi zawierać tylko litery.');
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM TYPY_POJAZDU
    WHERE NAZWA = :NEW.NAZWA;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Taki typ pojazdu już istnieje.');
    END IF;
END;
/



create or replace TRIGGER TRG_TYPY_BRONI_WALIDACJE
BEFORE INSERT OR UPDATE ON TYPY_BRONI
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    IF :NEW.NAZWA IS NULL OR TRIM(:NEW.NAZWA) = '' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Nazwa typu broni nie może być pusta.');
    END IF;

    IF REGEXP_LIKE(:NEW.NAZWA, '[A-Za-ząćęłńóśżźĄĆĘŁŃÓŚŻŹ]') THEN
        RAISE_APPLICATION_ERROR(-20002, 'Nazwa typu broni musi zawierać tylko litery.');
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM TYPY_BRONI
    WHERE NAZWA = :NEW.NAZWA;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Taki typ broni już istnieje.');
    END IF;
END;
/


create or replace TRIGGER TRG_STOPNIE_WALIDACJE
BEFORE INSERT OR UPDATE ON STOPNIE
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    IF :NEW.NAZWA_STOPNIA IS NULL OR TRIM(:NEW.NAZWA_STOPNIA) = '' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Nazwa stopnia nie może być pusta.');
    END IF;

    IF REGEXP_LIKE(:NEW.NAZWA_STOPNIA, '[^A-Za-ząćęłńóśżźĄĆĘŁŃÓŚŻŹ]') THEN
        RAISE_APPLICATION_ERROR(-20003, 'Nazwa stopnia musi zawierać tylko litery.');
    END IF;

    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM STOPNIE
        WHERE NAZWA_STOPNIA = :NEW.NAZWA_STOPNIA
        AND (:NEW.NAZWA_STOPNIA != :OLD.NAZWA_STOPNIA OR :OLD.NAZWA_STOPNIA IS NULL);
        
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20004, 'Taka nazwa stopnia już istnieje.');
        END IF;
    END;
END;
/


create or replace TRIGGER TRG_POLIGONY_WALIDACJE
BEFORE INSERT OR UPDATE ON POLIGONY
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION; 
    v_count NUMBER;
BEGIN
    IF :NEW.NAZWA IS NULL OR :NEW.LOKALIZACJA IS NULL OR :NEW.CZYNY IS NULL OR :NEW.ID_POLIGONU IS NULL THEN
        RAISE_APPLICATION_ERROR(-20004, 'Wszystkie pola muszą być wypełnione.');
    END IF;

    IF LENGTH(:NEW.ID_POLIGONU) != 6 OR NOT REGEXP_LIKE(:NEW.ID_POLIGONU, '^\d{6}$') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Id poligonu musi składać się z dokładnie 6 cyfr.');
    END IF;

    IF INSERTING THEN
        SELECT COUNT(*) INTO v_count FROM POLIGONY WHERE ID_POLIGONU = :NEW.ID_POLIGONU;
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Taki id poligonu już istnieje.');
        END IF;
    END IF;

    SELECT COUNT(*) INTO v_count 
    FROM POLIGONY 
    WHERE NAZWA = :NEW.NAZWA 
    AND (:NEW.ID_POLIGONU != ID_POLIGONU);

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Taka nazwa poligonu już istnieje.');
    END IF;
    COMMIT;
END;
/


create or replace TRIGGER TRG_POJAZDY_WALIDACJE
BEFORE INSERT OR UPDATE ON POJAZDY
FOR EACH ROW
DECLARE
    pragma autonomous_transaction;
    v_count NUMBER;
BEGIN
    IF :NEW.ID_POJAZDU IS NULL OR :NEW.MODEL IS NULL OR :NEW.POJEMNOSC_ZBIORNIKA_W_LITRACH IS NULL OR :NEW.PRZEBIEG_W_KM IS NULL OR :NEW.TYP_POJAZDU IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Wszystkie dane muszą być wypełnione.');
    END IF;

    IF LENGTH(TO_CHAR(:NEW.ID_POJAZDU)) != 6 OR NOT REGEXP_LIKE(TO_CHAR(:NEW.ID_POJAZDU), '^\d{6}$') THEN
        RAISE_APPLICATION_ERROR(-20002, 'Id pojazdu musi składać się z dokładnie 6 cyfr.');
    END IF;

    IF INSERTING THEN
        SELECT COUNT(*) INTO v_count
        FROM POJAZDY
        WHERE ID_POJAZDU = :NEW.ID_POJAZDU;

        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Takie id pojazdu już istnieje.');
        END IF;
    END IF;

    IF :NEW.MODEL IS NOT NULL THEN
        SELECT COUNT(*) INTO v_count
        FROM POJAZDY
        WHERE MODEL = :NEW.MODEL
          AND (ID_POJAZDU != :NEW.ID_POJAZDU OR :NEW.ID_POJAZDU IS NULL); 

        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20004, 'Taki model pojazdu już istnieje.');
        END IF;
    END IF;
    COMMIT;
END;
/


create or replace TRIGGER TRG_OPERACJE_WALIDACJE
BEFORE INSERT OR UPDATE ON OPERACJE
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    IF :NEW.NAZWA_OPERACJI IS NULL OR :NEW.ID_MISJI IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Wszystkie pola muszą być wypełnione.');
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM OPERACJE
    WHERE NAZWA_OPERACJI = :NEW.NAZWA_OPERACJI
      AND (:OLD.NAZWA_OPERACJI IS NULL OR :OLD.NAZWA_OPERACJI != :NEW.NAZWA_OPERACJI);

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Taka nazwa operacji już istnieje.');
    END IF;
END;
/


create or replace TRIGGER TRG_MISJE_WALIDACJE
BEFORE INSERT OR UPDATE ON MISJE
FOR EACH ROW
DECLARE
    pragma autonomous_transaction;
    v_count NUMBER;
BEGIN
    IF :NEW.ID_MISJI IS NULL OR :NEW.NAZWA IS NULL OR :NEW.LICZBA_ZOLNIERZY IS NULL OR :NEW.LICZBA_AMUNICJI IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Wszystkie dane muszą być wypełnione.');
    END IF;

    IF LENGTH(TO_CHAR(:NEW.ID_MISJI)) != 6 OR NOT REGEXP_LIKE(TO_CHAR(:NEW.ID_MISJI), '^\d{6}$') THEN
        RAISE_APPLICATION_ERROR(-20002, 'Id misji musi składać się z dokładnie 6 cyfr.');
    END IF;

    IF INSERTING THEN
        SELECT COUNT(*) INTO v_count
        FROM MISJE
        WHERE ID_MISJI = :NEW.ID_MISJI;

        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Taki id misji już istnieje.');
        END IF;
    END IF;


    SELECT COUNT(*) INTO v_count
    FROM MISJE
    WHERE NAZWA = :NEW.NAZWA
      AND (:OLD.NAZWA IS NULL OR NAZWA != :OLD.NAZWA);

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Taka nazwa misji już istnieje.');
    END IF;
    COMMIT;
END;
/


create or replace TRIGGER TRG_MISJE_POJAZDY_WALIDACJE
BEFORE INSERT OR UPDATE ON MISJE_POJAZDY
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    IF :NEW.ID_MISJI IS NULL OR :NEW.ID_POJAZDU IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Wszystkie dane muszą być wypełnione.');
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM MISJE_POJAZDY
    WHERE ID_MISJI = :NEW.ID_MISJI
    AND ID_POJAZDU = :NEW.ID_POJAZDU;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Taka kombinacja misji i pojazdu już istnieje.');
    END IF;
END;
/


create or replace TRIGGER TRG_BRON_WALIDACJE
BEFORE INSERT OR UPDATE ON BRON
FOR EACH ROW
DECLARE
    pragma autonomous_transaction;
    v_count NUMBER;
BEGIN
    IF NOT REGEXP_LIKE(:NEW.ID_BRONI, '^\d{6}$') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Id broni musi składać się z 6 cyfr.');
    END IF;

    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM BRON
        WHERE ID_BRONI = :NEW.ID_BRONI
        AND (:NEW.ID_BRONI != :OLD.ID_BRONI OR :OLD.ID_BRONI IS NULL);

        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Taki id broni już istnieje.');
        END IF;
    END;

    IF :NEW.MODEL IS NULL OR :NEW.KALIBER_MM IS NULL OR :NEW.DLUGOSC_LUFY_MM IS NULL OR :NEW.LICZBA_MAGAZYNIKOW IS NULL OR :NEW.WAGA_W_KG IS NULL OR :NEW.NAZWA_TYPU IS NULL OR :NEW.NAZWA_AMUNICJI IS NULL THEN
        RAISE_APPLICATION_ERROR(-20003, 'Wszystkie dane muszą być wypełnione.');
    END IF;

    IF :NEW.MODEL IS NOT NULL THEN
        SELECT COUNT(*) INTO v_count
        FROM BRON
        WHERE MODEL = :NEW.MODEL
          AND (ID_BRONI != :NEW.ID_BRONI OR :NEW.ID_BRONI IS NULL);

        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20004, 'Taki model broni już istnieje.');
        END IF;
    END IF;

    COMMIT;
END;
/



create or replace TRIGGER TRG_AMUNICJA_WALIDACJE
BEFORE INSERT OR UPDATE ON AMUNICJA
FOR EACH ROW
DECLARE
    pragma autonomous_transaction;
    v_count NUMBER;
BEGIN
    IF :NEW.NAZWA IS NULL OR :NEW.DLUGOSC_NABOJU_W_MM IS NULL OR :NEW.LICZBA_W_MAGAZYNIE IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Wszystkie dane muszą być wypełnione.');
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM AMUNICJA
    WHERE NAZWA = :NEW.NAZWA
    AND (:NEW.NAZWA != :OLD.NAZWA OR :OLD.NAZWA IS NULL);

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Taka nazwa amunicji już istnieje.');
    END IF;
    COMMIT;
END;
/





create or replace TRIGGER TRG_ZOLNIERZE_DELETE
BEFORE DELETE ON ZOLNIERZE
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION; 
    v_dowodca_count NUMBER;
    v_poligon_count NUMBER;
    v_misja_count NUMBER;
    v_bron_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_dowodca_count
    FROM ZOLNIERZE
    WHERE PESEL_DOWODCY = :old.PESEL;

    SELECT COUNT(*)
    INTO v_poligon_count
    FROM ZOLNIERZE_POLIGONY
    WHERE PESEL_ZOLNIERZA = :old.PESEL;

    SELECT COUNT(*)
    INTO v_misja_count
    FROM ZOLNIERZE_MISJE
    WHERE PESEL_ZOLNIERZA = :old.PESEL;

    SELECT COUNT(*)
    INTO v_bron_count
    FROM ZOLNIERZE_BRON
    WHERE PESEL_ZOLNIERZA = :old.PESEL;

    IF v_dowodca_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Nie można usunąć żołnierza, ponieważ jest dowódcą innych żołnierzy.');
    ELSIF v_poligon_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Nie można usunąć żołnierza, ponieważ jest przypisany do pola bitwy.');
    ELSIF v_misja_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Nie można usunąć żołnierza, ponieważ jest przypisany do misji.');
    ELSIF v_bron_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Nie można usunąć żołnierza, ponieważ posiada broń.');
    END IF;
    COMMIT;
END;
/


CREATE OR REPLACE TRIGGER TRG_POLIGONY_DELETE
BEFORE DELETE ON POLIGONY
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM ZOLNIERZE_POLIGONY
    WHERE ID_POLIGONU = :old.ID_POLIGONU;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Nie można usunąć pola bitwy, ponieważ są przypisani do niego żołnierze.');
    END IF;
END;


create or replace TRIGGER TRG_MISJE_DELETE
BEFORE DELETE ON MISJE
FOR EACH ROW
DECLARE
    v_zolnierz_count NUMBER;
    v_operacja_count NUMBER;
    v_pojazd_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_zolnierz_count
    FROM ZOLNIERZE_MISJE
    WHERE ID_MISJI = :old.ID_MISJI;

    SELECT COUNT(*)
    INTO v_operacja_count
    FROM OPERACJE
    WHERE ID_MISJI = :old.ID_MISJI;

    SELECT COUNT(*)
    INTO v_pojazd_count
    FROM MISJE_POJAZDY
    WHERE ID_MISJI = :old.ID_MISJI;

    IF v_zolnierz_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20006, 'Nie można usunąć misji, ponieważ są przypisani do niej żołnierze.');
    ELSIF v_operacja_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20007, 'Nie można usunąć misji, ponieważ zawiera operację/operacje.');
    ELSIF v_pojazd_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20008, 'Nie można usunąć misji, ponieważ przypisane są do niej pojazdy.');
    END IF;
END;
/


CREATE OR REPLACE TRIGGER TRG_POJAZDY_DELETE
BEFORE DELETE ON POJAZDY
FOR EACH ROW
DECLARE
    v_misja_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_misja_count
    FROM MISJE_POJAZDY
    WHERE ID_POJAZDU = :old.ID_POJAZDU;

    IF v_misja_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20009, 'Nie można usunąć pojazdu, ponieważ jest przypisany do misji.');
    END IF;
END;
/


CREATE OR REPLACE TRIGGER TRG_TYPY_POJAZDU_DELETE
BEFORE DELETE ON TYPY_POJAZDU
FOR EACH ROW
DECLARE
    v_pojazd_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_pojazd_count
    FROM POJAZDY
    WHERE TYP_POJAZDU = :old.NAZWA;

    IF v_pojazd_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'Nie można usunąć typu pojazdu, ponieważ jest przypisany do pojazdu.');
    END IF;
END;
/


CREATE OR REPLACE TRIGGER TRG_BRON_DELETE
BEFORE DELETE ON BRON
FOR EACH ROW
DECLARE
    v_zolnierz_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_zolnierz_count
    FROM ZOLNIERZE_BRON
    WHERE ID_BRONI = :old.ID_BRONI;

    IF v_zolnierz_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20011, 'Nie można usunąć broni, ponieważ jest przypisana do żołnierza.');
    END IF;
END;
/


CREATE OR REPLACE TRIGGER TRG_TYPY_BRONI_DELETE
BEFORE DELETE ON TYPY_BRONI
FOR EACH ROW
DECLARE
    v_bron_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_bron_count
    FROM BRON
    WHERE NAZWA_TYPU = :old.NAZWA;

    IF v_bron_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20012, 'Nie można usunąć typu broni, ponieważ jest przypisany do broni.');
    END IF;
END;
/


CREATE OR REPLACE TRIGGER TRG_AMUNICJA_DELETE
BEFORE DELETE ON AMUNICJA
FOR EACH ROW
DECLARE
    v_bron_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_bron_count
    FROM BRON
    WHERE NAZWA_AMUNICJI = :old.NAZWA;

    IF v_bron_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20013, 'Nie można usunąć amunicji, ponieważ jest przypisana do broni.');
    END IF;
END;
/
