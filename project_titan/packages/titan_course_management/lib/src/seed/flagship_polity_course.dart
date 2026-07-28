import 'package:titan_academy/titan_academy.dart';
import '../models/kmp_course_models.dart';

/// Flagship Course: UPSC Civil Services - Indian Polity Foundation.
///
/// Contains the complete 10-module curriculum hierarchy:
/// Course -> Module -> Chapter -> Lesson
class FlagshipPolityCourseSeed {
  static const String courseId = 'course_upsc_polity_foundation';

  static Instructor get instructor => const Instructor(
        id: 'inst_upsc_polity_lead',
        name: 'Dr. M. Laxmikanth & TITAN Editorial Board',
        title: 'Senior UPSC Polity & Constitutional Law Faculty',
        bio:
            'Renowned expert in Indian Polity and Governance with 20+ years of UPSC mentorship experience.',
        avatarUrl: 'assets/images/instructors/laxmikanth.png',
        qualifications: [
          'M.A. Political Science',
          'Ph.D. Constitutional Law',
          'Author, Indian Polity'
        ],
        rating: 4.95,
        studentCount: 150000,
      );

  static KmpCourseMetadata get metadata => KmpCourseMetadata(
        authorId: 'titan_editorial_board',
        authorName: 'TITAN Educational Content Division',
        primaryLanguage: 'English',
        supportedLanguages: const ['English', 'Hindi'],
        tags: const [
          'UPSC',
          'Civil Services',
          'Polity',
          'Constitution',
          'Prelims',
          'Mains',
          'Flagship'
        ],
        category: ExamCategory.upsc,
        difficulty: KmpDifficulty.advanced,
        estimatedHours: 85,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 7, 28),
      );

  static KmpLearningPath get learningPath => const KmpLearningPath(
        id: 'path_upsc_polity_foundation_mastery',
        title: 'UPSC Civil Services - Indian Polity Foundation Mastery',
        description:
            'Complete 10-module flagship learning journey for UPSC Prelims & Mains Polity.',
        targetExam: ExamCategory.upsc,
        courseIdsSequence: [courseId],
        isPublished: true,
      );

  static Course buildCourse() {
    return Course(
      id: courseId,
      title: 'UPSC Civil Services – Indian Polity Foundation',
      description:
          'The flagship comprehensive course covering Constitutional Framework, Governance, Rights, and State Institutions for UPSC CSE Prelims & Mains.',
      subject: 'Indian Polity & Governance',
      level: 'Advanced',
      instructor: instructor,
      estimatedHours: 85.0,
      rating: 4.95,
      enrolledCount: 12500,
      imageUrl: 'assets/images/courses/upsc_polity_foundation.png',
      tags: const [
        'UPSC',
        'Civil Services',
        'Indian Polity',
        'Constitutional Law',
        'Governance',
        'Flagship'
      ],
      knowledgeNodeId: 'node_upsc_polity_root',
      modules: [
        // Module 1: Historical Background
        Module(
          id: 'mod_polity_01',
          courseId: courseId,
          title: 'Module 1: Historical Background',
          description:
              'Evolution of constitutional developments during Company Rule (1773-1858) and Crown Rule (1858-1947).',
          durationMinutes: 360,
          chapters: [
            Chapter(
              id: 'chap_polity_01_01',
              moduleId: 'mod_polity_01',
              title: 'Company Rule (1773–1858)',
              description:
                  'Regulating Act of 1773, Pitt’s India Act 1784, and Charter Acts of 1813, 1833, 1853.',
              durationMinutes: 180,
              lessons: const [
                Lesson(
                  id: 'les_polity_01_01_01',
                  chapterId: 'chap_polity_01_01',
                  title: 'Regulating Act of 1773 & Pitt’s India Act of 1784',
                  description:
                      'First step by British Govt to control East India Company affairs and creation of dual control.',
                  durationMinutes: 90,
                  type: 'article',
                  content:
                      'The Regulating Act of 1773 laid the foundation of central administration in India. It designated Governor of Bengal as Governor-General of Bengal (Lord Warren Hastings) and established the Supreme Court at Fort William, Calcutta in 1774. Pitt’s India Act of 1784 distinguished between commercial and political functions, creating the Board of Control.',
                  order: 1,
                  topic: 'Company Rule',
                ),
                Lesson(
                  id: 'les_polity_01_01_02',
                  chapterId: 'chap_polity_01_01',
                  title: 'Charter Acts of 1813, 1833, and 1853',
                  description:
                      'Termination of EIC trade monopoly, centralization of power, and introduction of open competition for civil services.',
                  durationMinutes: 90,
                  type: 'article',
                  content:
                      'Charter Act 1813 ended trade monopoly except in tea and trade with China. Charter Act 1833 made Governor-General of Bengal as Governor-General of India (Lord William Bentinck) and ended EIC commercial activities. Charter Act 1853 separated legislative and executive functions of GG Council.',
                  order: 2,
                  topic: 'Company Rule',
                ),
              ],
            ),
            Chapter(
              id: 'chap_polity_01_02',
              moduleId: 'mod_polity_01',
              title: 'Crown Rule (1858–1947)',
              description:
                  'Government of India Acts 1858, 1919, 1935, and Indian Independence Act 1947.',
              durationMinutes: 180,
              lessons: const [
                Lesson(
                  id: 'les_polity_01_02_01',
                  chapterId: 'chap_polity_01_02',
                  title: 'Government of India Act of 1858 & Councils Acts',
                  description:
                      'Transfer of governance to British Crown, creation of Secretary of State for India, and Indian Councils Acts 1861, 1892, 1909.',
                  durationMinutes: 90,
                  type: 'article',
                  content:
                      'GoI Act 1858 abolished EIC and Board of Control, creating Secretary of State for India. Indian Councils Act 1861 introduced portfolio system. Morley-Minto Reforms (1909) introduced separate electorates for Muslims.',
                  order: 1,
                  topic: 'Crown Rule',
                ),
                Lesson(
                  id: 'les_polity_01_02_02',
                  chapterId: 'chap_polity_01_02',
                  title:
                      'GoI Act 1919, GoI Act 1935 & Indian Independence Act 1947',
                  description:
                      'Montagu-Chelmsford dyarchy, provincial autonomy, federal scheme, and division into India and Pakistan.',
                  durationMinutes: 90,
                  type: 'article',
                  content:
                      'GoI Act 1919 introduced Dyarchy in provinces and bicameralism at center. GoI Act 1935 provided for all-India federation and provincial autonomy, dividing powers into Federal, Provincial, Concurrent lists. Indian Independence Act 1947 declared India an independent sovereign state.',
                  order: 2,
                  topic: 'Crown Rule',
                ),
              ],
            ),
          ],
        ),

        // Module 2: Making of the Constitution
        Module(
          id: 'mod_polity_02',
          courseId: courseId,
          title: 'Module 2: Making of the Constitution',
          description:
              'Formation of Constituent Assembly, Cabinet Mission Plan, Drafting Committee, Objectives Resolution, and adoption.',
          durationMinutes: 300,
          chapters: [
            Chapter(
              id: 'chap_polity_02_01',
              moduleId: 'mod_polity_02',
              title: 'Constituent Assembly & Drafting',
              description:
                  'Demand, composition, working, committees, and adoption of the Constitution.',
              durationMinutes: 300,
              lessons: const [
                Lesson(
                  id: 'les_polity_02_01_01',
                  chapterId: 'chap_polity_02_01',
                  title:
                      'Demand, Composition & Working of Constituent Assembly',
                  description:
                      'Idea proposed by M.N. Roy (1934), Cabinet Mission Plan 1946 composition, Sachchidananda Sinha and Dr. Rajendra Prasad leadership.',
                  durationMinutes: 150,
                  type: 'article',
                  content:
                      'Constituent Assembly held its first meeting on Dec 9, 1946. Nehru moved Objectives Resolution on Dec 13, 1946. Total strength 389, reduced to 299 post-partition. It took 2 years, 11 months and 18 days to draft the Constitution.',
                  order: 1,
                  topic: 'Constituent Assembly',
                ),
                Lesson(
                  id: 'les_polity_02_01_02',
                  chapterId: 'chap_polity_02_01',
                  title: 'Drafting Committee, Enactment & Criticism',
                  description:
                      'Dr. B.R. Ambedkar leadership, key committees, adoption on Nov 26 1949 and commencement on Jan 26 1950.',
                  durationMinutes: 150,
                  type: 'article',
                  content:
                      'Drafting Committee set up on Aug 29, 1947 under Dr. B.R. Ambedkar. Preamble, 395 Articles, 8 Schedules enacted on Nov 26, 1949. Jan 26 chosen as Republic Day to commemorate Poorna Swaraj declaration of 1930.',
                  order: 2,
                  topic: 'Constituent Assembly',
                ),
              ],
            ),
          ],
        ),

        // Module 3: Salient Features
        Module(
          id: 'mod_polity_03',
          courseId: courseId,
          title: 'Module 3: Salient Features of the Constitution',
          description:
              'Major features, borrowed features from global constitutions, federal vs unitary debate, and basic structure.',
          durationMinutes: 240,
          chapters: [
            Chapter(
              id: 'chap_polity_03_01',
              moduleId: 'mod_polity_03',
              title: 'Salient Features & Borrowed Sources',
              description:
                  'Structural characteristics and global constitutional inspirations.',
              durationMinutes: 240,
              lessons: const [
                Lesson(
                  id: 'les_polity_03_01_01',
                  chapterId: 'chap_polity_03_01',
                  title:
                      'Lengthiest Constitution, Rigidity vs Flexibility & Federal Features',
                  description:
                      'Analysis of why Indian Constitution is lengthiest written constitution, unique blend of amendment procedures, and quasi-federal nature.',
                  durationMinutes: 120,
                  type: 'article',
                  content:
                      'India has the longest written constitution due to geographical diversity, GoI Act 1935 influence, and single constitution for Center and States. K.C. Wheare described it as quasi-federal.',
                  order: 1,
                  topic: 'Salient Features',
                ),
                Lesson(
                  id: 'les_polity_03_01_02',
                  chapterId: 'chap_polity_03_01',
                  title:
                      'Sources of Indian Constitution & Parliamentary System',
                  description:
                      'Detailed mapping of borrowings from UK, USA, Ireland, Canada, Australia, Germany, USSR, South Africa, Japan.',
                  durationMinutes: 120,
                  type: 'article',
                  content:
                      'GoI Act 1935 (structural blueprint), UK (parliamentary form, rule of law, single citizenship), USA (FRs, judicial review, preamble), Ireland (DPSP), Canada (federation with strong center), Australia (concurrent list).',
                  order: 2,
                  topic: 'Salient Features',
                ),
              ],
            ),
          ],
        ),

        // Module 4: Preamble
        Module(
          id: 'mod_polity_04',
          courseId: courseId,
          title: 'Module 4: Preamble of the Constitution',
          description:
              'Philosophy, keywords, amendability, landmark judgments (Berubari, Kesavananda Bharati, LIC of India).',
          durationMinutes: 240,
          chapters: [
            Chapter(
              id: 'chap_polity_04_01',
              moduleId: 'mod_polity_04',
              title: 'Preamble Philosophy & Key Terminology',
              description:
                  'Detailed study of Sovereign, Socialist, Secular, Democratic, Republic, Justice, Liberty, Equality, Fraternity.',
              durationMinutes: 240,
              lessons: const [
                Lesson(
                  id: 'les_polity_04_01_01',
                  chapterId: 'chap_polity_04_01',
                  title: 'Text & Key Concepts of Preamble',
                  description:
                      'Analysis of Objectives Resolution foundation, source of authority, nature of Indian state, and constitutional goals.',
                  durationMinutes: 120,
                  type: 'article',
                  content:
                      'Preamble serves as the preface to the Constitution. Sovereign means independent authority. Socialist (added by 42nd Amendment 1976) implies democratic socialism. Secular implies positive secularism. Democratic republic ensures rule of people.',
                  order: 1,
                  topic: 'Preamble',
                ),
                Lesson(
                  id: 'les_polity_04_01_02',
                  chapterId: 'chap_polity_04_01',
                  title: 'Preamble as Part of Constitution & Amendability',
                  description:
                      'Evolution from Berubari Union (1960) to Kesavananda Bharati (1973) and LIC of India (1995) rulings.',
                  durationMinutes: 120,
                  type: 'article',
                  content:
                      'Berubari Union 1960 held Preamble is NOT part of Constitution. Kesavananda Bharati 1973 overruled it, holding Preamble IS an integral part of Constitution and amendable under Art 368 subject to basic structure.',
                  order: 2,
                  topic: 'Preamble',
                ),
              ],
            ),
          ],
        ),

        // Module 5: Union & Territory
        Module(
          id: 'mod_polity_05',
          courseId: courseId,
          title: 'Module 5: Union & Its Territory',
          description:
              'Articles 1 to 4, reorganizations of states, Dhar Commission, JVP Committee, Fazl Ali Commission.',
          durationMinutes: 240,
          chapters: [
            Chapter(
              id: 'chap_polity_05_01',
              moduleId: 'mod_polity_05',
              title: 'Articles 1-4 & State Reorganisation',
              description:
                  'Constitutional scheme for territory of India and evolution of states.',
              durationMinutes: 240,
              lessons: const [
                Lesson(
                  id: 'les_polity_05_01_01',
                  chapterId: 'chap_polity_05_01',
                  title: 'Articles 1 to 4: Union of States & Parliament Powers',
                  description:
                      'Article 1 (India that is Bharat), Article 2 (admission/establishment of new states), Article 3 (reorganization of existing states), Article 4 (law under Art 2 & 3 not Art 368 amendment).',
                  durationMinutes: 120,
                  type: 'article',
                  content:
                      'Article 1 describes India as a Union of States rather than Federation of States. Parliament under Article 3 can alter boundaries, areas, or names of states without state consent, making India an indestructible union of destructible states.',
                  order: 1,
                  topic: 'Union & Territory',
                ),
                Lesson(
                  id: 'les_polity_05_01_02',
                  chapterId: 'chap_polity_05_01',
                  title:
                      'Integration of Princely States & Reorganisation Commissions',
                  description:
                      'Sardar Patel role, Dhar Commission (1948), JVP Committee (1948), Fazl Ali Commission (1953), States Reorganisation Act 1956.',
                  durationMinutes: 120,
                  type: 'article',
                  content:
                      'Fazl Ali Commission rejected one language one state theory but accepted linguistic reorganization. 7th Constitutional Amendment Act 1956 created 14 States and 6 Union Territories.',
                  order: 2,
                  topic: 'Union & Territory',
                ),
              ],
            ),
          ],
        ),

        // Module 6: Citizenship
        Module(
          id: 'mod_polity_06',
          courseId: courseId,
          title: 'Module 6: Citizenship',
          description:
              'Articles 5 to 11, Citizenship Act 1955, modes of acquisition/loss, NRI, PIO, OCI, CAA.',
          durationMinutes: 240,
          chapters: [
            Chapter(
              id: 'chap_polity_06_01',
              moduleId: 'mod_polity_06',
              title: 'Constitutional & Statutory Citizenship Provisions',
              description:
                  'Constitutional provisions at commencement and Citizenship Act 1955 scheme.',
              durationMinutes: 240,
              lessons: const [
                Lesson(
                  id: 'les_polity_06_01_01',
                  chapterId: 'chap_polity_06_01',
                  title:
                      'Articles 5 to 11: Constitutional Provisions on Citizenship',
                  description:
                      'Citizenship at commencement of Constitution (Art 5), rights of migrants from/to Pakistan (Art 6-7), persons of Indian origin residing outside India (Art 8).',
                  durationMinutes: 120,
                  type: 'article',
                  content:
                      'Article 5-11 deal with citizenship at commencement (Jan 26, 1950). Article 9 provides for loss of citizenship upon voluntary acquisition of foreign state citizenship. Article 11 empowers Parliament to regulate citizenship by law.',
                  order: 1,
                  topic: 'Citizenship',
                ),
                Lesson(
                  id: 'les_polity_06_01_02',
                  chapterId: 'chap_polity_06_01',
                  title: 'Citizenship Act 1955: Acquisition, Loss & OCI',
                  description:
                      'Acquisition by Birth, Descent, Registration, Naturalisation, Incorporation of Territory; Loss by Renunciation, Termination, Deprivation; CAA 2019 provisions.',
                  durationMinutes: 120,
                  type: 'article',
                  content:
                      'Citizenship Act 1955 prescribes 5 ways of acquiring citizenship and 3 ways of losing it. CAA 2019 provided fast-track citizenship for persecuted minorities from Afghanistan, Bangladesh, Pakistan entering before Dec 31, 2014.',
                  order: 2,
                  topic: 'Citizenship',
                ),
              ],
            ),
          ],
        ),

        // Module 7: Fundamental Rights
        Module(
          id: 'mod_polity_07',
          courseId: courseId,
          title: 'Module 7: Fundamental Rights',
          description:
              'Articles 12 to 35, Magna Carta of India, 6 categories of rights, Writs under Article 32, basic structure.',
          durationMinutes: 480,
          chapters: [
            Chapter(
              id: 'chap_polity_07_01',
              moduleId: 'mod_polity_07',
              title: 'General Provisions & Right to Equality (Articles 12–18)',
              description:
                  'Definition of State (Art 12), Judicial Review (Art 13), Equality before Law & Equal Protection (Art 14-18).',
              durationMinutes: 240,
              lessons: const [
                Lesson(
                  id: 'les_polity_07_01_01',
                  chapterId: 'chap_polity_07_01',
                  title:
                      'Articles 12 & 13: Definition of State & Laws Inconsistent with FRs',
                  description:
                      'Scope of State under Art 12, doctrine of eclipse, doctrine of severability, judicial review power of Supreme Court & High Courts.',
                  durationMinutes: 120,
                  type: 'article',
                  content:
                      'Article 12 defines State to include Executive, Legislature, Local Authorities, and other statutory bodies. Article 13 declares all laws inconsistent with FRs void. Basic structure doctrine laid down in Kesavananda Bharati case 1973.',
                  order: 1,
                  topic: 'Fundamental Rights',
                ),
                Lesson(
                  id: 'les_polity_07_01_02',
                  chapterId: 'chap_polity_07_01',
                  title: 'Articles 14 to 18: Right to Equality & Reservations',
                  description:
                      'Equality before law (UK) vs Equal protection of laws (USA), prohibition of discrimination (Art 15), equality of opportunity in public employment (Art 16), abolition of untouchability (Art 17), abolition of titles (Art 18).',
                  durationMinutes: 120,
                  type: 'article',
                  content:
                      'Article 14 allows reasonable classification based on intelligible differentia. Article 15(4) & 16(4) enable affirmative action for SC, ST, OBC, and EWS (103rd Amendment 2019). Article 17 is absolute in nature.',
                  order: 2,
                  topic: 'Fundamental Rights',
                ),
              ],
            ),
            Chapter(
              id: 'chap_polity_07_02',
              moduleId: 'mod_polity_07',
              title:
                  'Freedoms, Protection & Constitutional Remedies (Articles 19–35)',
              description:
                  'Article 19 six freedoms, Article 21 life & liberty, Article 32 writ jurisdiction.',
              durationMinutes: 240,
              lessons: const [
                Lesson(
                  id: 'les_polity_07_02_01',
                  chapterId: 'chap_polity_07_02',
                  title:
                      'Articles 19 to 22: Right to Freedom, Life & Personal Liberty',
                  description:
                      'Six freedoms under Art 19(1), protection in respect of conviction for offenses (Art 20), expansion of Art 21 post Maneka Gandhi (1978), Right to Education (Art 21A), protection against arrest & detention (Art 22).',
                  durationMinutes: 120,
                  type: 'article',
                  content:
                      'Article 19 guarantees 6 freedoms subject to reasonable restrictions under Art 19(2)-(6). Article 21 includes right to privacy (Puttaswamy 2017), clean environment, and dignity. Article 20 & 21 cannot be suspended during National Emergency.',
                  order: 1,
                  topic: 'Fundamental Rights',
                ),
                Lesson(
                  id: 'les_polity_07_02_02',
                  chapterId: 'chap_polity_07_02',
                  title:
                      'Article 32: Right to Constitutional Remedies & Supreme Court Writs',
                  description:
                      'Dr. Ambedkar called Art 32 Heart and Soul of Constitution. 5 Writs: Habeas Corpus, Mandamus, Prohibition, Certiorari, Quo-Warranto.',
                  durationMinutes: 120,
                  type: 'article',
                  content:
                      'Article 32 gives direct right to approach Supreme Court for FR enforcement. Habeas Corpus produces the body; Mandamus commands performance of public duty; Prohibition stops inferior courts; Certiorari quashes illegal orders; Quo-Warranto checks title to public office.',
                  order: 2,
                  topic: 'Fundamental Rights',
                ),
              ],
            ),
          ],
        ),

        // Module 8: Directive Principles of State Policy
        Module(
          id: 'mod_polity_08',
          courseId: courseId,
          title: 'Module 8: Directive Principles of State Policy (DPSP)',
          description:
              'Articles 36 to 51, Part IV, Socialistic, Gandhian, Liberal-Intellectual principles, conflict with FRs.',
          durationMinutes: 300,
          chapters: [
            Chapter(
              id: 'chap_polity_08_01',
              moduleId: 'mod_polity_08',
              title: 'Classification of DPSPs & Judicial Interplay',
              description:
                  'Categorization of directives, key amendments, and FR-DPSP relationship.',
              durationMinutes: 300,
              lessons: const [
                Lesson(
                  id: 'les_polity_08_01_01',
                  chapterId: 'chap_polity_08_01',
                  title:
                      'Socialistic, Gandhian & Liberal-Intellectual Directives',
                  description:
                      'Articles 38-39A (social welfare), Art 40 (Gram Panchayats), Art 44 (Uniform Civil Code), Art 45 (childhood care), Art 48A (environment), Art 51 (international peace).',
                  durationMinutes: 150,
                  type: 'article',
                  content:
                      'DPSPs borrowed from Irish Constitution (1937). Non-justiciable in nature (Art 37) but fundamental in governance. 42nd Amendment added Arts 39(f), 39A, 43A, 48A. 44th Amendment added Art 38(2). 86th Amendment modified Art 45.',
                  order: 1,
                  topic: 'Directive Principles',
                ),
                Lesson(
                  id: 'les_polity_08_01_02',
                  chapterId: 'chap_polity_08_01',
                  title:
                      'Conflict & Harmony Between Fundamental Rights and DPSPs',
                  description:
                      'Evolution from Champakam Dorairajan (1951), Golaknath (1967), 25th Amendment (1971), Kesavananda (1973), to Minerva Mills (1980) harmony doctrine.',
                  durationMinutes: 150,
                  type: 'article',
                  content:
                      'In Champakam Dorairajan 1951 Supreme Court held FRs prevail over DPSP. Minerva Mills 1980 established that Indian Constitution is founded on the bedrock of balance between FRs and DPSPs.',
                  order: 2,
                  topic: 'Directive Principles',
                ),
              ],
            ),
          ],
        ),

        // Module 9: Fundamental Duties
        Module(
          id: 'mod_polity_09',
          courseId: courseId,
          title: 'Module 9: Fundamental Duties',
          description:
              'Article 51A, Part IV-A, Swaran Singh Committee, 42nd & 86th Amendments, 11 duties, enforcement.',
          durationMinutes: 240,
          chapters: [
            Chapter(
              id: 'chap_polity_09_01',
              moduleId: 'mod_polity_09',
              title: 'Swaran Singh Committee & 11 Fundamental Duties',
              description:
                  'Origin, list of duties, Verma Committee recommendations, and legal enforceability.',
              durationMinutes: 240,
              lessons: const [
                Lesson(
                  id: 'les_polity_09_01_01',
                  chapterId: 'chap_polity_09_01',
                  title:
                      'Origin, Swaran Singh Committee & 42nd/86th Amendments',
                  description:
                      'Incorporated upon recommendations of Swaran Singh Committee (1976) inspired by USSR constitution. 10 duties added by 42nd Amendment 1976; 11th duty added by 86th Amendment 2002.',
                  durationMinutes: 120,
                  type: 'article',
                  content:
                      'Fundamental Duties incorporated in Part IV-A Article 51A. 11th Duty (Art 51A(k)) mandates parent/guardian to provide education opportunities to children between 6 to 14 years.',
                  order: 1,
                  topic: 'Fundamental Duties',
                ),
                Lesson(
                  id: 'les_polity_09_01_02',
                  chapterId: 'chap_polity_09_01',
                  title: 'List of 11 Fundamental Duties & Legal Enforceability',
                  description:
                      'Detailed text of 51A(a) to 51A(k), non-justiciable nature, and statutory provisions (Prevention of Insults to National Honour Act 1971, Wildlife Protection Act 1972) enforcing duties.',
                  durationMinutes: 120,
                  type: 'article',
                  content:
                      'Verma Committee (1999) identified existing legal provisions for enforcement of certain Fundamental Duties. Supreme Court in AIIMS Students Union case held duties are equally important as rights.',
                  order: 2,
                  topic: 'Fundamental Duties',
                ),
              ],
            ),
          ],
        ),

        // Module 10: Amendment Procedure
        Module(
          id: 'mod_polity_10',
          courseId: courseId,
          title: 'Module 10: Amendment Procedure of the Constitution',
          description:
              'Article 368, Part XX, Simple majority, Special majority, Special majority + State ratification, Basic Structure Doctrine.',
          durationMinutes: 300,
          chapters: [
            Chapter(
              id: 'chap_polity_10_01',
              moduleId: 'mod_polity_10',
              title: 'Article 368 & Basic Structure Doctrine',
              description:
                  'Procedure for amendment, types of majorities, and judicial limitations on amending power.',
              durationMinutes: 300,
              lessons: const [
                Lesson(
                  id: 'les_polity_10_01_01',
                  chapterId: 'chap_polity_10_01',
                  title: 'Article 368: Procedure & Types of Amendments',
                  description:
                      'Initiation in either House, special majority requirement, joint sitting prohibition, presidential assent compulsory (24th Amendment 1971), 3 types of amendment pathways.',
                  durationMinutes: 150,
                  type: 'article',
                  content:
                      'Article 368 in Part XX prescribes procedure to amend Constitution. Three types: 1) Simple majority (outside Art 368), 2) Special majority under Art 368, 3) Special majority + Ratification by 50% state legislatures.',
                  order: 1,
                  topic: 'Amendment Procedure',
                ),
                Lesson(
                  id: 'les_polity_10_01_02',
                  chapterId: 'chap_polity_10_01',
                  title:
                      'Scope of Amending Power & Basic Structure Doctrine Rulings',
                  description:
                      'Shankari Prasad (1951), Sajjan Singh (1965), Golaknath (1967), Kesavananda Bharati (1973), Indira Gandhi (1975), Minerva Mills (1980), IR Coelho (2007).',
                  durationMinutes: 150,
                  type: 'article',
                  content:
                      'Kesavananda Bharati case (April 24, 1973) held Parliament has wide power to amend any part of Constitution including FRs, but cannot alter the basic structure. IR Coelho 2007 held laws in 9th Schedule post April 24, 1973 subject to judicial review.',
                  order: 2,
                  topic: 'Amendment Procedure',
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
