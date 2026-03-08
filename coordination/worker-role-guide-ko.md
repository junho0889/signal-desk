# SignalDesk 작업자 역할 안내서

## 목적
이 문서는 SignalDesk 프로젝트에서 쓰는 작업자 구조를 한국어로 설명하는 온보딩 문서다.

대상:
- 처음 프로젝트에 들어온 신입
- 어떤 스레드가 무엇을 하는지 헷갈리는 사람
- 왜 이렇게 역할을 나눠서 일하는지 이해해야 하는 사람

이 문서를 읽으면 아래를 이해해야 한다.
- 현재 작업자 목록
- 각 작업자의 책임 범위
- 어떤 작업을 누구에게 맡겨야 하는지
- 왜 문서, handoff, task, worktree가 필요한지
- 실제 IT 회사에서는 이런 식으로 어떻게 대응되는지

## 먼저 이해해야 할 핵심
SignalDesk는 한 사람이 이것저것 동시에 만지는 방식이 아니라, 역할을 나눈 작은 팀처럼 운영한다.

즉, 이 프로젝트의 기본 철학은 아래와 같다.
- 역할을 나눈다
- 역할별 책임을 분명히 한다
- 계약 문서를 먼저 고정한다
- 구현은 그다음 한다
- 구현 후에는 검증한다
- 다음 사람에게 넘길 때는 handoff를 남긴다

이 방식의 목적은 단순하다.
- 작업 충돌을 줄인다
- 누가 무엇을 책임지는지 분명하게 만든다
- 나중에 문제를 추적하기 쉽게 만든다
- 병렬 작업을 가능하게 만든다

## 현재 고정된 작업자 목록
현재 사용자에게 보여줄 때는 아래 이름만 쓴다.

- `Collector`
- `BE-storage`
- `MODEL`
- `TRUST`
- `DESIGN`
- `APP`
- `Mobile thread`
- `QA thread`
- `Ops thread`
- `Backend thread`
- `Orchestrator thread`

이 이름은 바꾸지 않는다.
실무에서 이름이 자꾸 바뀌면 혼선이 생긴다. 그래서 프로젝트에서는 고정 이름을 유지한다.

## 작업자별 설명

### 1. `Orchestrator thread`
가장 중요한 총괄 작업자다.

이 작업자의 책임:
- 전체 우선순위 결정
- 어떤 일을 먼저 할지 정리
- 어떤 작업자를 언제 투입할지 결정
- 작업이 서로 충돌하지 않게 관리
- handoff, resume, tasks 상태 확인
- 계약이 바뀌었는지 검토
- 최종적으로 어떤 작업을 수용할지 판단

쉽게 말하면:
- 팀장
- 프로젝트 매니저
- 기술 조정자

이 작업자가 직접 모든 코드를 다 짜는 것이 목표는 아니다.
이 작업자의 핵심은 "작업이 올바른 순서로, 올바른 사람에게, 올바른 기준으로 진행되게 만드는 것"이다.

신입이 자주 하는 오해:
- 오케스트레이터가 제일 많이 코드를 짜야 한다고 생각함

실제로는:
- 오케스트레이터는 많이 짜는 사람보다 많이 판단하는 사람에 가깝다

### 2. `Collector`
수집기 전담 작업자다.

이 작업자의 책임:
- 수집기 구조 설계
- source adapter 설계 및 구현
- spool DB 적재
- retry 정책
- metadata 정리
- Pi 배포 대상 collector 구성
- 수집 품질 기준 정의

쉽게 말하면:
- 데이터를 "가져오는 사람"
- 하지만 단순히 긁어오는 것이 아니라, 신뢰 가능한 원본 데이터를 구조적으로 쌓는 사람

중요한 점:
- AI가 없어도 이 작업자는 일할 수 있어야 한다
- metadata, idempotency, timestamp, source identity, duplicate 처리만 잘해도 좋은 수집기는 만들 수 있다

SignalDesk에서 이 역할이 중요한 이유:
- 잘못된 데이터를 많이 모으는 것보다
- 적은 양이어도 품질 높은 데이터를 정확히 모으는 것이 더 중요하기 때문이다

### 3. `BE-storage`
저장 구조와 DB 계약을 담당한다.

이 작업자의 책임:
- DB schema 설계
- raw/normalized/trust/model/publish 레이어 구분
- lineage 추적 구조 설계
- retention 규칙 설계
- quality state 저장 구조 설계
- source registry, raw item, dead letter, quarantine 테이블 구조 고정

쉽게 말하면:
- "어디에, 어떤 모양으로, 얼마나 오래 저장할지"를 책임지는 사람

이 역할이 약하면 생기는 문제:
- 데이터는 모였는데 나중에 왜 이 점수가 나왔는지 설명 불가
- 중복인지 새 데이터인지 구분 불가
- 삭제 정책이 없어 DB가 엉망이 됨

### 4. `Backend thread`
백엔드 API와 intake 계약, 처리 순서를 담당한다.

이 작업자의 책임:
- intake API 계약
- validation 규칙
- accept/reject/quarantine/downgrade 정책
- public API 계약 유지
- 내부 job 순서 정의
- alert 및 publish 동작 정의

쉽게 말하면:
- 외부에서 들어온 데이터를 시스템 안으로 안전하게 받아들이는 사람
- 앱이 읽을 수 있는 API 형태를 책임지는 사람

중요한 점:
- `Backend thread`는 DB 자체를 설계하는 역할과는 다르다
- 저장 구조를 직접 정의하는 쪽은 `BE-storage`
- 처리 규칙과 API 계약은 `Backend thread`

### 5. `MODEL`
랭킹 모델과 평가 체계를 담당한다.

이 작업자의 책임:
- feature 정의
- ranking output 정의
- explainability 계약 정의
- evaluation 기준 정의
- online path와 offline research path 구분

쉽게 말하면:
- "이 정보가 왜 중요한가?"를 점수로 만드는 사람

중요한 점:
- 이 프로젝트에서 `MODEL`은 처음부터 딥러닝을 돌리는 역할이 아니다
- 먼저 explainable model을 만든다
- 나중에 데이터와 라벨이 쌓이면 learned model로 확장한다

### 6. `TRUST`
정보의 신뢰성과 위험 신호를 담당한다.

이 작업자의 책임:
- trust score 정의
- contradiction 처리
- stale 상태 판단
- misinformation-risk 규칙
- warning 후보 정의
- manual review escalation 규칙 정의

쉽게 말하면:
- "이 데이터가 믿을 만한가?"를 판단하는 사람

모델과의 차이:
- `MODEL`은 중요도와 순위를 다룸
- `TRUST`는 신뢰도와 위험을 다룸

이 둘은 비슷해 보이지만 다르다.
중요한 뉴스와 믿을 만한 뉴스는 항상 같지 않다.

### 7. `DESIGN`
디자인 시스템과 화면 구조를 담당한다.

이 작업자의 책임:
- 정보 구조 설계
- 화면 위계 정리
- 차트/카드/상태 화면 패턴 정의
- typography, spacing, action placement 규칙 정의
- "아마추어처럼 보이지 않는" 기준 정리

쉽게 말하면:
- 화면이 왜 이렇게 보여야 하는지를 정하는 사람

중요한 점:
- 예쁜 그림만 만드는 역할이 아니다
- 사용자가 한눈에 이해할 수 있는 정보 구조를 만드는 역할이다

### 8. `APP`
앱 구현 계획과 실제 UI 반영 전환을 맡는 모바일 작업자다.

이 작업자의 책임:
- 디자인 결과를 구현 가능한 컴포넌트 구조로 번역
- 앱 화면 shell 정의
- 공통 컴포넌트 구조 정리
- chart, trust, freshness 같은 UI를 실제 앱 구조에 맞게 반영

쉽게 말하면:
- 디자인 문서를 Flutter 코드로 옮길 준비를 하는 사람

### 9. `Mobile thread`
실제 Flutter 코드 구현 작업자다.

이 작업자의 책임:
- 기능 구현
- 화면 구현
- 상태 처리
- 한국어/영어 토글 같은 실제 사용자 기능 반영
- analyzer/test/run 실행

쉽게 말하면:
- 사용자 눈에 보이는 앱을 실제로 만드는 사람

`APP`와 차이:
- `APP`는 계획과 구조
- `Mobile thread`는 실제 구현

프로젝트에서 둘을 나눈 이유:
- 계획 중인 작업과 구현 중인 작업이 섞이면 충돌이 생기기 쉽기 때문이다

### 10. `Ops thread`
실행 환경과 배포, 운영 절차를 담당한다.

이 작업자의 책임:
- Docker Compose 구성
- 로컬 실행 방법 정리
- Pi 배포 절차 정리
- 재시작, 로그 확인, 복구 절차 정리
- 운영 runbook 작성

쉽게 말하면:
- "이걸 실제로 켜고, 굴리고, 문제 나면 살리는 사람"

### 11. `QA thread`
검증 전담 작업자다.

이 작업자의 책임:
- 구현된 내용을 다시 확인
- 실제 defect 찾기
- blocker와 polish issue 구분
- 재현 방법 정리
- release gate 판단

쉽게 말하면:
- "됐다고 말하기 전에 진짜 됐는지 확인하는 사람"

중요한 점:
- QA는 문서만 많이 읽는 사람이 아니다
- 실제로 실행하고, 다시 보고, 틀린 점을 찾는 사람이다

## 각 작업자가 언제 투입되는가

### 설계 단계
주로 움직이는 작업자:
- `Orchestrator thread`
- `Collector`
- `BE-storage`
- `Backend thread`
- `MODEL`
- `TRUST`
- `DESIGN`

이 단계의 목적:
- 계약을 고정
- 구현 전에 서로 해석이 갈리지 않게 만들기

### 구현 단계
주로 움직이는 작업자:
- `Collector`
- `Mobile thread`
- `Backend thread`
- `Ops thread`

이 단계의 목적:
- 실제 코드와 실행 결과 만들기

### 검증 단계
주로 움직이는 작업자:
- `QA thread`
- `Orchestrator thread`

이 단계의 목적:
- 진짜 되는지 확인
- 다음 단계로 넘어갈 수 있는지 판단

## 실제 IT 회사에서도 이렇게 하나?
결론부터 말하면:
- 네, 방향은 비슷하다
- 다만 실제 회사에서는 도구와 조직 형태가 더 크고 복잡하다

비슷한 점:
- 역할을 나눈다
- 백엔드, 프론트엔드, 데이터, QA, DevOps를 분리한다
- 계약 문서를 먼저 고정한다
- 구현 후 PR 리뷰를 한다
- 배포 전 검증을 한다
- 장애 대응 절차를 둔다

다른 점:
- 실제 회사는 보통 Markdown handoff만 쓰지 않는다
- 아래 같은 도구를 같이 쓴다
  - Jira
  - Confluence
  - Slack
  - GitHub PR
  - CI/CD
  - Sentry
  - Datadog

즉, 우리 구조는 실제 회사 방식을 "repo 중심으로 단순화한 버전"이라고 보면 된다.

## 실제 회사에서 이 역할은 보통 어떤 이름으로 존재하나

### `Orchestrator thread`
실제 회사 대응:
- Tech Lead
- Engineering Manager
- Staff Engineer
- TPM

### `Collector`
실제 회사 대응:
- Data Engineer
- Ingestion Engineer
- Platform Engineer

### `BE-storage`
실제 회사 대응:
- Backend Engineer
- Data Platform Engineer
- Database Engineer

### `Backend thread`
실제 회사 대응:
- Backend Engineer
- API Engineer

### `MODEL`
실제 회사 대응:
- ML Engineer
- Applied Scientist
- Ranking Engineer

### `TRUST`
실제 회사 대응:
- Trust & Safety Engineer
- Information Quality Engineer
- Applied ML / Risk Engineer

### `DESIGN`
실제 회사 대응:
- Product Designer
- UX Designer
- Interaction Designer

### `APP` / `Mobile thread`
실제 회사 대응:
- Mobile Engineer
- Frontend Engineer

### `Ops thread`
실제 회사 대응:
- DevOps Engineer
- SRE
- Platform Engineer

### `QA thread`
실제 회사 대응:
- QA Engineer
- Test Engineer
- Release Engineer

## 왜 이런 분리가 신입에게 중요하나
신입이 가장 많이 실수하는 부분은 아래다.
- 모든 걸 한 번에 해결하려고 함
- 설계와 구현과 테스트를 섞음
- 누가 책임지는지 생각하지 않음
- 문서를 안 읽고 바로 코드를 고침
- 검증 없이 끝났다고 판단함

이 프로젝트에서는 이런 실수를 막기 위해 역할을 나눈다.

신입이 꼭 기억할 것:
- 내 역할이 아닌 파일은 함부로 건드리지 않는다
- 먼저 읽고, 그다음 바꾼다
- 계약이 바뀌면 문서를 먼저 고친다
- 끝났다고 생각해도 검증 전에는 끝난 게 아니다
- 다음 사람이 이어받을 수 있게 handoff를 남긴다

## 이 프로젝트에서 일하는 기본 순서
모든 작업자는 아래 순서를 기본으로 지킨다.

1. `AGENTS.md` 읽기
2. `coordination/working-agreement.md` 읽기
3. `coordination/tasks.yaml`에서 내 task 확인
4. 해당 dispatch 읽기
5. resume 읽기
6. 필요한 문서만 읽기
7. 작업
8. 검증
9. handoff 작성
10. resume 업데이트

## handoff는 왜 중요한가
실제 회사에서도 인수인계가 약하면 프로젝트가 망가진다.

handoff에 반드시 들어가야 하는 것:
- 내가 무엇을 했는지
- 무엇이 아직 안 됐는지
- 어떤 명령으로 검증했는지
- 어떤 blocker가 있는지
- 다음 사람이 어디서부터 시작해야 하는지

좋은 handoff 예시:
- "collector fixture ingest 성공"
- "spool row 2개 적재 확인"
- "idempotency rerun 성공"
- "Pi 배포는 SSH 로그인 미확인으로 보류"

나쁜 handoff 예시:
- "대충 끝남"
- "아마 될 듯"
- "나중에 보면 됨"

## 수집기처럼 중요한 영역은 어떻게 운영해야 하나
SignalDesk에서 수집기는 핵심이다.
그래서 수집기에는 아래 원칙을 더 강하게 적용한다.

- 문서보다 실행 결과가 중요하다
- metadata가 없는 데이터는 가치가 낮다
- source identity가 없으면 신뢰도가 떨어진다
- duplicate 처리 없이 많이 모으는 것은 오히려 해롭다
- Pi 배포 전에는 로컬 test DB 증거가 있어야 한다
- Pi 배포 후에는 원격 명령 기록이 남아야 한다

즉, 수집기 작업자는 "데이터를 많이 넣는 사람"이 아니라 "좋은 데이터를 구조적으로 남기는 사람"이어야 한다.

## 마지막 정리
이 프로젝트의 작업자 구조는 복잡해 보일 수 있다.
하지만 본질은 단순하다.

- 한 사람이 모든 걸 하지 않는다
- 역할별 책임을 나눈다
- 계약을 먼저 고정한다
- 구현 후 검증한다
- 다음 사람이 이어받을 수 있게 남긴다

실제 IT 회사도 결국 비슷하다.
도구와 규모만 더 클 뿐, 잘하는 팀은 거의 항상 이 원칙을 지킨다.

신입 기준으로 가장 중요한 한 줄은 이것이다.

"내가 맡은 역할을 정확히 이해하고, 내가 바꾼 결과를 다음 사람이 이어받을 수 있게 남겨라."
