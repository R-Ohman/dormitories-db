/*
1. Niektórzy studenci zalegają z opłatami. Sporządź zestawienie 20 studentów,
którzy mają największą łączną sumę nieopłaconych od co najmniej miesiąca faktur,
wraz z ich (podstawowymi i dodatkowymi) numerami telefonów, aby można im było wysłać upomnienie.
*/
WITH UnpaidInvoices AS (
    SELECT
        s.NumerIndeksu,
        SUM(f.Wysokosc) AS Zadluzenie
    FROM
        Studenci s
        JOIN Mieszkancy m ON s.NumerKontaktowy = m.NumerKontaktowy
        JOIN Faktury f ON m.NumerKontaktowy = f.NumerKontaktowy
    WHERE
        f.Zaplacono = 0
		AND f.Data <= DATEADD(MONTH, -1, GETDATE())
    GROUP BY
        s.NumerIndeksu
)

SELECT TOP 20
    s.NumerIndeksu,
    s.NumerKontaktowy,
    s.DodatkowyNumerKontaktowy,
    ui.Zadluzenie
FROM
    UnpaidInvoices ui
    JOIN Studenci s ON ui.NumerIndeksu = s.NumerIndeksu
ORDER BY
    ui.Zadluzenie DESC;


/*
2. Centrum Zakwaterowania przeprowadza rozdział pokoi w akademikach. Pierwszeństwo mają studenci, którzy mają najwięcej punktów rankingowych.
- Uporządkuj mieszkańców według liczby ich punktów.
Punkty przyznawane są za aktywność studencką oraz za semestry (6 miesięcy) spędzone w akademiku (5 punktów za każdy semestr).
*/
WITH RankedStudents AS (
    SELECT
        S.NumerIndeksu,
        S.NumerKontaktowy,
        SUM(COALESCE(A.LiczbaPunktow, 0)) + 
            5 * (
                CEILING(
                    SUM(
                        DATEDIFF(MONTH, Zk.DataOd, 
                            CASE 
                                WHEN Zk.DataDo > GETDATE() THEN GETDATE() 
                                ELSE Zk.DataDo 
                            END
                        )
                    ) / 6.0
                )
        ) AS Rank
    FROM
        Studenci S
        LEFT JOIN Zajmowanie Z ON S.NumerIndeksu = Z.NumerIndeksu
        LEFT JOIN Aktywnosci A ON Z.ID_Aktywnosc = A.ID
        LEFT JOIN Zakwaterowania Zk ON S.NumerKontaktowy = Zk.NumerKontaktowy
    GROUP BY
        S.NumerIndeksu,
        S.NumerKontaktowy
)
SELECT
    RS.NumerIndeksu,
    RS.NumerKontaktowy,
    RS.Rank
FROM
    RankedStudents RS
ORDER BY
    RS.Rank DESC;


/*
3. Dział Spraw Studenckich chce przydzielić specjalne stypendium studentom pierwszego roku,
którzy mają najwięcej punktów za dodatkowe aktywności i jednocześnie nie zalegają z opłatami za akademik (brak niespłaconych faktur starszych niż miesiąc).
Znajdź pięciu takich studentów.
*/
WITH ExtraPoints AS (
    SELECT
        Z.NumerIndeksu,
        SUM(A.LiczbaPunktow) AS PunktyDodatkowe
    FROM
        Zajmowanie Z
        INNER JOIN Aktywnosci A ON Z.ID_Aktywnosc = A.ID
    GROUP BY
        Z.NumerIndeksu
    HAVING
        SUM(A.LiczbaPunktow) > 0
)

SELECT TOP 5
    S.NumerIndeksu,
    S.NumerKontaktowy,
    S.DodatkowyNumerKontaktowy,
    E.PunktyDodatkowe
FROM
    Studenci S
    INNER JOIN ExtraPoints E ON S.NumerIndeksu = E.NumerIndeksu
    LEFT JOIN (
        SELECT
            F.NumerKontaktowy
        FROM
            Faktury F
        WHERE
            F.Zaplacono = 0
            AND F.Data < DATEADD(MONTH, -1, GETDATE())
    ) UnpaidInvoices ON S.NumerKontaktowy = UnpaidInvoices.NumerKontaktowy
WHERE
    UnpaidInvoices.NumerKontaktowy IS NULL
ORDER BY
    E.PunktyDodatkowe DESC;


/*
4. Księgowa prowadzi raport finansowy dla Politechniki Gdańskiej
- Uporządkuj wydziały (malejąco), według łącznej sumy (kwoty z faktur za akademik) jaką generują studenci tych wydziałów.
*/
WITH DepartmentTotalAmount AS (
    SELECT
        W.NazwaSkrocona,
        SUM(F.Wysokosc) AS LacznaKwota
    FROM
        Wydzialy W
        JOIN Studiowania S ON W.NazwaSkrocona = S.Wydzial
        JOIN Studenci Stu ON S.NumerIndeksu = Stu.NumerIndeksu
        LEFT JOIN Faktury F ON Stu.NumerKontaktowy = F.NumerKontaktowy
    GROUP BY
        W.NazwaSkrocona
)

SELECT
    D.NazwaSkrocona,
    D.LacznaKwota
FROM
    DepartmentTotalAmount D
ORDER BY
    D.LacznaKwota DESC;


/*
5. Pewien student poszukuje jaknajtańszego pokoju w osiedlu przy ulicy Wyspańskiego.
- Wyszukaj wolne pokoje.
*/
WITH FreeRooms AS (
    SELECT
        P.NumerDS,
        P.NumerPokoju,
        RP.RodzajPokoju,
        C.Cena,
        CASE 
			WHEN COUNT(Z.ID) = 0 AND RP.RodzajPokoju LIKE '%2-os%' THEN 2
			ELSE 1
		END AS WolneMiejsca
    FROM
        Pokoje P
        JOIN Cenniki C ON P.ID_Rodzaju = C.ID_Rodzaju AND P.NumerDS = C.NumerDS
        JOIN RodzajePokojow RP ON P.ID_Rodzaju = RP.ID
        LEFT JOIN Zakwaterowania Z ON P.NumerPokoju = Z.NumerPokoju AND P.NumerDS = Z.NumerDS AND Z.DataDo > GETDATE()
        JOIN Akademiki A ON P.NumerDS = A.NumerDS
    WHERE
        A.Adres LIKE '%Wyspiańskiego%'
    GROUP BY
        P.NumerDS,
        P.NumerPokoju,
        RP.RodzajPokoju,
        C.Cena
    HAVING
        COUNT(Z.ID) = 0
        OR (COUNT(Z.ID) = 1 AND RP.RodzajPokoju LIKE '%2-os%')
)
SELECT
    FR.NumerDS,
    FR.NumerPokoju,
    FR.RodzajPokoju,
    FR.Cena
FROM
    FreeRooms FR
ORDER BY
    FR.Cena ASC;


/*
6. Księgowa prowadzi raport finansowy dla Politechniki Gdańskiej
- Uporządkuj akademiki (malejąco), według łącznej sumy (kwoty z faktur za zamieszkanie)
jaką generują mieszkańcy tych akademików. Także podaj  liczbę wystawionych faktur.
*/
WITH DormitoryTotalAmount AS (
    SELECT
        Z.NumerDS,
        SUM(COALESCE(F.Wysokosc, 0)) AS LacznaKwota,
        COUNT(F.Numer) AS LiczbaFaktur
    FROM
        Zakwaterowania Z
        LEFT JOIN Faktury F ON Z.NumerKontaktowy = F.NumerKontaktowy
    WHERE
        Z.DataDo > GETDATE()
    GROUP BY
        Z.NumerDS
)
SELECT
    D.NumerDS,
    D.LacznaKwota,
    D.LiczbaFaktur
FROM
    DormitoryTotalAmount D
ORDER BY
    D.LacznaKwota DESC;


/*
7. Nadchodzi lato, niektóre akademiki (nr.1,3,5) powinny zostać zwolnione. Zwróć listę studentów, które mogą stracić miejsce w akademiku.
- Uporządkuj studentów według liczby ich punktów.
Punkty przyznawane są za aktywność studencką oraz za semestry (6 miesięcy) spędzone w akademiku (5 punktów za każdy semestr).
*/
WITH RankedStudents AS (
    SELECT
        S.NumerIndeksu,
        S.NumerKontaktowy,
        SUM(COALESCE(A.LiczbaPunktow, 0)) + 
            5 * (
                CEILING(
                    SUM(
                        DATEDIFF(MONTH, Zk.DataOd, 
                            CASE 
                                WHEN Zk.DataDo > GETDATE() THEN GETDATE() 
                                ELSE Zk.DataDo 
                            END
                        )
                    ) / 6.0
                )
        ) AS Rank
    FROM
        Studenci S
        LEFT JOIN Zajmowanie Z ON S.NumerIndeksu = Z.NumerIndeksu
        LEFT JOIN Aktywnosci A ON Z.ID_Aktywnosc = A.ID
        LEFT JOIN Zakwaterowania Zk ON S.NumerKontaktowy = Zk.NumerKontaktowy
    WHERE
        Zk.NumerDS IN (1, 3, 5)
    GROUP BY
        S.NumerIndeksu,
        S.NumerKontaktowy
)
SELECT
    RS.NumerIndeksu,
    RS.NumerKontaktowy,
    RS.Rank
FROM
    RankedStudents RS
ORDER BY
    RS.Rank DESC;


/*
8. Księgowa prowadzi raport finansowy dla Politechniki Gdańskiej
- Uporządkuj akademiki (malejąco), według łącznej sumy nieopłaconych faktur. Także podaj ich liczbę.
*/
WITH DormitoryTotalAmount AS (
    SELECT
        Z.NumerDS,
        SUM(COALESCE(F.Wysokosc, 0)) AS LacznaKwota,
        COUNT(F.Numer) AS LiczbaFaktur
    FROM
        Zakwaterowania Z
        LEFT JOIN Faktury F ON Z.NumerKontaktowy = F.NumerKontaktowy
    WHERE
        Z.DataDo > GETDATE() AND
        F.Zaplacono = 0
    GROUP BY
        Z.NumerDS
)
SELECT
    D.NumerDS,
    D.LacznaKwota,
    D.LiczbaFaktur
FROM
    DormitoryTotalAmount D
ORDER BY
    D.LacznaKwota DESC;


/*
9. W akademikach brakuje miejsc dla studentów pierwszego roku. Wyszukaj mieszkańców akademika,
którzy nie są studentami, a także absolwentów, którzy zalegają z opłatami za akademik (niespłacone faktury starsze niż miesiąc).
*/
WITH UnpaidResidents AS (
    SELECT
        M.NumerKontaktowy,
        M.Imie,
        M.Nazwisko
    FROM
        Mieszkancy M
    WHERE
        M.NumerKontaktowy IN (
            SELECT DISTINCT
                S.NumerKontaktowy
            FROM
                Studenci S
                JOIN Studiowania St ON S.NumerIndeksu = St.NumerIndeksu
                JOIN Faktury F ON S.NumerKontaktowy = F.NumerKontaktowy
            WHERE
                St.DataDo < GETDATE()
                AND F.Zaplacono = 0
                AND F.Data < DATEADD(MONTH, -1, GETDATE())
        )
        OR M.NumerKontaktowy NOT IN (
            SELECT
                S.NumerKontaktowy
            FROM
                Studenci S
        )
)
SELECT
    UR.NumerKontaktowy,
    UR.Imie,
    UR.Nazwisko
FROM
    UnpaidResidents UR;


/*
10. Niektórzy mieszkańcy zalegają z opłatami. Sporządź zestawienie wszystkich mieszkańców,
podając łączną sumę nieopłaconych od co najmniej miesiąca faktur,
wraz z ich numerami telefonów, aby można im było wysłać upomnienie.
*/
IF OBJECT_ID('ResidentsUnpaidInvoices', 'V') IS NOT NULL
    DROP VIEW ResidentsUnpaidInvoices;

GO 
CREATE VIEW ResidentsUnpaidInvoices AS
SELECT
	M.Imie,
    M.Nazwisko,
    M.NumerKontaktowy,
    SUM(CASE
			WHEN F.Zaplacono = 0 AND F.Data < DATEADD(MONTH, -1, GETDATE())
				THEN F.Wysokosc
			ELSE 0
		END) AS SumaNieoplaconychFaktur
FROM
    Mieszkancy M
    LEFT JOIN Faktury F ON M.NumerKontaktowy = F.NumerKontaktowy
GROUP BY
    M.NumerKontaktowy,
    M.Imie,
    M.Nazwisko
HAVING SUM(CASE
			WHEN F.Zaplacono = 0 AND F.Data < DATEADD(MONTH, -1, GETDATE())
				THEN F.Wysokosc
			ELSE 0
		END) > 0;

GO
SELECT
    NumerKontaktowy,
	Imie,
    Nazwisko,
    SumaNieoplaconychFaktur
FROM ResidentsUnpaidInvoices
ORDER BY
    SumaNieoplaconychFaktur DESC;
