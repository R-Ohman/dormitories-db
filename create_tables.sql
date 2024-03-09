CREATE TABLE Mieszkancy (
    NumerKontaktowy VARCHAR(9) PRIMARY KEY CHECK (NumerKontaktowy LIKE REPLICATE('[0-9]', 9)),
    Imie NVARCHAR(32) NOT NULL CHECK (Imie LIKE '[A-ZĄĆĘŁŃÓŚŹŻ]%'),
    Nazwisko NVARCHAR(32) NOT NULL CHECK (Nazwisko LIKE '[A-ZĄĆĘŁŃÓŚŹŻ]%')
);

CREATE TABLE Akademiki (
    NumerDS INT PRIMARY KEY CHECK (NumerDS > 0),
    Adres NVARCHAR(128) NOT NULL,
    Telefon VARCHAR(9) NOT NULL CHECK (Telefon LIKE REPLICATE('[0-9]', 9)),
    Standard NVARCHAR(400)
);

CREATE TABLE Faktury (
    Numer VARCHAR(24) PRIMARY KEY,
    Data DATE NOT NULL CHECK (YEAR(Data) BETWEEN 2000 AND 2100),
    Zaplacono BIT DEFAULT 0,
    Wysokosc DECIMAL(10, 2) NOT NULL CHECK (Wysokosc > 0),
    NumerKontaktowy VARCHAR(9) NOT NULL CHECK (NumerKontaktowy LIKE REPLICATE('[0-9]', 9)),
    FOREIGN KEY (NumerKontaktowy) REFERENCES Mieszkancy(NumerKontaktowy) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Studenci (
    NumerIndeksu INT PRIMARY KEY CHECK (NumerIndeksu > 0),
    NumerKontaktowy VARCHAR(9) NOT NULL CHECK (NumerKontaktowy LIKE REPLICATE('[0-9]', 9)),
    DodatkowyNumerKontaktowy VARCHAR(9) DEFAULT NULL,
    Narodowosc NVARCHAR(32) NOT NULL,
    AdresZamieszkania NVARCHAR(128) NOT NULL,
    FOREIGN KEY (NumerKontaktowy) REFERENCES Mieszkancy(NumerKontaktowy) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Aktywnosci (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Nazwa NVARCHAR(128) UNIQUE NOT NULL,
    LiczbaPunktow INT NOT NULL CHECK (LiczbaPunktow > 0)
);

CREATE TABLE Zajmowanie (
    ID_Aktywnosc INT NOT NULL,
    NumerIndeksu INT NOT NULL CHECK (NumerIndeksu > 0),
    FOREIGN KEY (ID_Aktywnosc) REFERENCES Aktywnosci(ID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (NumerIndeksu) REFERENCES Studenci(NumerIndeksu) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE RodzajePokojow (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    RodzajPokoju NVARCHAR(64) UNIQUE NOT NULL
);

CREATE TABLE Cenniki (
    ID_Rodzaju INT NOT NULL,
    NumerDS INT NOT NULL,
    Cena DECIMAL(6, 2) NOT NULL CHECK (Cena > 0),
    PRIMARY KEY (NumerDS, ID_Rodzaju),
    FOREIGN KEY (ID_Rodzaju) REFERENCES RodzajePokojow(ID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (NumerDS) REFERENCES Akademiki(NumerDS) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Pokoje (
    NumerPokoju NVARCHAR(5) NOT NULL CHECK (
        NumerPokoju LIKE '[1-9][0-9][0-9]' OR 
        NumerPokoju LIKE '[1-9][0-9][0-9][A-C]' OR 
        NumerPokoju LIKE '[1-9][0-9][0-9][A-C][1-4]'
    ),
    NumerDS INT NOT NULL,
    ID_Rodzaju INT NOT NULL,
	PRIMARY KEY(NumerPokoju, NumerDS),
    FOREIGN KEY (NumerDS, ID_Rodzaju) REFERENCES Cenniki(NumerDS, ID_Rodzaju) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (NumerDS) REFERENCES Akademiki(NumerDS) ON DELETE NO ACTION
);

CREATE TABLE Zakwaterowania (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    DataOd DATE NOT NULL CHECK (YEAR(DataOd) BETWEEN 2000 AND 2100),
    DataDo DATE CHECK (YEAR(DataDo) BETWEEN 2000 AND 2100),
    NumerKontaktowy VARCHAR(9) NOT NULL CHECK (NumerKontaktowy LIKE REPLICATE('[0-9]', 9)),
    NumerPokoju NVARCHAR(5) NOT NULL CHECK (
        NumerPokoju LIKE '[1-9][0-9][0-9]' OR 
        NumerPokoju LIKE '[1-9][0-9][0-9][A-C]' OR 
        NumerPokoju LIKE '[1-9][0-9][0-9][A-C][1-4]'
    ),
    NumerDS INT NOT NULL,
    FOREIGN KEY (NumerKontaktowy) REFERENCES Mieszkancy(NumerKontaktowy) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (NumerPokoju, NumerDS) REFERENCES Pokoje(NumerPokoju, NumerDS) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Wydzialy (
    NazwaSkrocona NVARCHAR(6) PRIMARY KEY,
    Nazwa NVARCHAR(64) NOT NULL,
    NumerBudynku INT NOT NULL CHECK (NumerBudynku > 0)
);

CREATE TABLE Przynalezenia (
    NumerDS INT NOT NULL,
    Wydzial NVARCHAR(6) NOT NULL,
    FOREIGN KEY (NumerDS) REFERENCES Akademiki(NumerDS) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (Wydzial) REFERENCES Wydzialy(NazwaSkrocona) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Studiowania (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    NumerIndeksu INT NOT NULL CHECK (NumerIndeksu > 0),
    Wydzial NVARCHAR(6) NOT NULL,
    DataOd DATE NOT NULL CHECK (YEAR(DataOd) BETWEEN 1904 AND 2100),
    DataDo DATE CHECK (YEAR(DataDo) BETWEEN 1904 AND 2100),
    Semestr INT NOT NULL CHECK(Semestr BETWEEN 1 AND 10),
    Stopien INT NOT NULL CHECK (Stopien BETWEEN 0 AND 3),
    Tryb NVARCHAR(20) NOT NULL CHECK (Tryb IN ('Stacjonarny', 'Niestacjonarny', 'Wieczorowy', 'Eksternistyczny')),
    FOREIGN KEY (NumerIndeksu) REFERENCES Studenci(NumerIndeksu) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (Wydzial) REFERENCES Wydzialy(NazwaSkrocona) ON DELETE CASCADE ON UPDATE CASCADE
);

GO
CREATE TRIGGER tr_Studenci_CheckDodatkowyNumerKontaktowy
ON Studenci
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
            SELECT 1
            FROM inserted i
            WHERE i.DodatkowyNumerKontaktowy IS NOT NULL
            AND (
                i.DodatkowyNumerKontaktowy = i.NumerKontaktowy
                OR i.DodatkowyNumerKontaktowy NOT LIKE REPLICATE('[0-9]', 9)
            )
        )
    BEGIN
        RAISERROR ('DodatkowyNumerKontaktowy check constraint violation', 16, 1);
		ROLLBACK TRANSACTION;
    END;
END;
