# 執行摘要

Harness 是一個現代化的持續交付（Continuous Delivery，CD）平台，由 AppDynamics 共同創辦人 Jyoti Bansal 於 2017 年創立，旨在自動化與簡化軟體交付流程【23†L129-L137】【34†L139-L147】。Harness 以 SaaS 模式提供服務，核心元件包括 **Harness Manager**（雲端控制平臺）和部署於客戶網路中的 **Harness Delegate** 代理伺服器【18†L138-L144】【31†L174-L183】。Delegate 負責執行管道（Pipeline）中的建置、測試與部署步驟，並通過安全的 WebSocket 連線將資料回傳給 Harness Manager【18†L152-L160】【31†L174-L183】。Harness 支援整合 Git 倉庫（GitHub、GitLab、Bitbucket、Azure Repos、AWS CodeCommit）與常見制品註冊表（如 Docker Hub、AWS ECR、GCR、ACR）、基礎架構工具（Terraform、Helm）、主要雲端服務（AWS、GCP、Azure）與監控系統等【38†L115-L123】【39†L155-L163】，實現從代碼提交到生產環境的全流程自動化。Harness 平臺內建多種部署策略（滾動、藍綠、金絲雀與功能旗標等）、觀察性與自動回滾機制（Continuous Verification）、細粒度角色權限控制（RBAC）、密鑰與機密管理，以及多租戶隔離等企業級功能【34†L145-L153】【34†L168-L173】【34†L175-L179】。與競品相比，Harness 的優勢在於「一站式」CI/CD 平臺結合 AI 驗證與全生命周期管理，儘管學習曲線較陡，企業需依實際規模付費。實際案例顯示，United Airlines 使用 Harness 後將部署時間從 22 分鐘縮短到 5 分鐘，提升 75% 速度，同時大幅降低手動工作量【52†L168-L172】【54†L269-L272】。本報告深入分析 Harness 的架構、功能、整合能力與案例，並與 GitLab、Argo CD、Spinnaker、Jenkins X 等工具比較，協助企業全面評估與採用。

## 公司與產品概述

Harness Inc. 成立於 2017 年，總部位於美國舊金山。由 Jyoti Bansal（曾任 AppDynamics 共同創辦人）擔任執行長，公司的使命是讓全球軟體團隊能「快速、可靠且高效地」交付代碼【22†L179-L187】【23†L129-L137】。Harness 最早聚焦於持續交付，後逐步拓展至完整 DevOps 平臺，包含持續整合（CI）、成本管理、功能旗標與安全測試等模組【23†L129-L137】。2024 年 9 月，Harness 發表開源版（Harness Open Source），對外提供包含代碼倉庫、雲端開發環境、CI/CD 與制品管理等功能，並以 Apache 2.0 許可證發布【16†L156-L164】【16†L206-L214】。官方網站宣稱，開源版針對所有開發者「零摩擦」（Zero Friction）設計，無須購買昂貴授權即可快速部署【16†L206-L214】。此外，Harness 採用開放核心模式：社群版（Community Edition）採用源代碼可見的 PolyForm Shield 許可證，企業版則需洽詢銷售獲取授權【36†L251-L259】【16†L206-L214】。這意味著 Harness 提供免費使用階層，並針對大規模企業提供分階段的付費方案（Essentials、Enterprise 等），具體定價通常需與供應商洽談。

## 核心平臺架構與組件

Harness 平臺主要分為兩大部分：**Harness Manager**（即平臺控制臺，SaaS或自建）與分佈於用戶基礎架構中的 **Harness Delegate**【18†L138-L144】【31†L174-L183】。Harness Manager 作為中央控制點，負責存儲所有管線配置、連接器設定、角色權限、審計紀錄等，而 Harness Delegate 安裝在用戶的網路或雲端環境中，作為執行管線任務的工作代理【18†L138-L144】【31†L174-L183】。Delegate 與 Harness Manager 之間以出站的 TLS 加密 WebSocket 通訊，回傳心跳與任務執行狀態，但實際部署活動則由 Delegate 發起並回傳結果【18†L152-L160】【20†L327-L334】。這種設計確保了安全隔離與可擴展性：客戶只需開放出站連線，便可安裝多個 Delegate 副本以支撐大規模併發工作【20†L242-L250】【20†L306-L314】。


```mermaid
graph LR
    HM([Harness Manager (SaaS)])
    subgraph Customer Infrastructure/VPC
        DELA([Harness Delegate])
        GIT[Git 倉庫 / SCM]
        K8S[Kubernetes / Docker Engine]
        CLOUD[(雲端資源、容器註冊表等)]
    end
    HM -- "安全 WSS 連線" --> DELA
    DELA --> GIT
    DELA --> K8S
    DELA --> CLOUD
    subgraph "CI/CD 流程"
        DELA -.-> HM
    end
```

圖：Harness 平臺架構示意圖。客戶環境內的 Harness Delegate 與雲端的 Harness Manager 透過加密通道通訊，並可訪問本地或雲端資源（代碼倉庫、Kubernetes、容器註冊表等）執行作業【18†L152-L160】【31†L174-L183】。

Harness 的平臺功能模組包括：**CI**、**CD / GitOps**、**Secrets 管理**、**角色權限控制 (RBAC)**、**審計日誌**、**儀表板/報表**等，各模組共享相同的管理平臺與用戶介面。利用可複用的管道模板與 YAML 配置，團隊能統一建立、審核與審計部署流程【34†L168-L173】【52†L168-L172】。平臺支援多租戶組織架構，帳戶資料隔離並在靜態時加密【5†L19-L22】。

## CI/CD 管道與工作流程

在 Harness 中，持續整合/持續交付（CI/CD）的工作流以「管道 (Pipeline)」方式呈現：每條管道包含多個階段（Stage），每個階段由若干步驟（Step）組成，可執行程式建置、單元測試、制品上傳、通知等任務【31†L74-L83】【25†L207-L210】。Harness 支援**容器化步驟**，可在每個步驟中指定容器映像並於代理上執行，確保環境一致且語言無關【31†L74-L83】。用戶可手動觸發管道，也可設定觸發器（Triggers）基於事件自動執行，例如代碼推送、合併請求、標籤發布，或排程觸發【25†L207-L210】【31†L74-L83】。

Harness 提供視覺化與 YAML 雙編輯器，可讓使用者拖曳組件建構管道，也可直接編輯 YAML 定義【31†L152-L160】【31†L158-L166】。在流程中，Harness 透過事先配置的 **連接器 (Connector)** 與第三方資源互動：例如使用「Git Connector」拉取原始碼、使用「Kubernetes Connector」連線到叢集、或使用雲端連接器發起 ECS、Lambda 等部署【20†L308-L314】【39†L155-L163】。下圖示意了一個典型的 Harness CI/CD 流程：開發者將程式碼提交到 Git，Harness 管道隨即啟動，由代理依序進行建置、測試、發佈制品，最後部署到目標環境，並將部署狀態傳回給 Manager 以供監控。

```mermaid
graph LR
    commit[提交代碼 (Git)]
    harness([Harness CI/CD 平臺])
    subgraph "Harness 工作流程"
      build(建置與測試 (在 Delegate 上執行))
      test(發布制品及通知)
      deploy(部署至目標環境)
    end
    users[使用者 / 生產環境]
    commit --> harness
    harness --> build
    build --> test
    test --> deploy
    deploy --> users
```

## 支援的部署策略

Harness 支援多種 **部署策略**，包括傳統的 **滾動更新**（Rolling Update）、**藍綠部署**（Blue-Green）、**金絲雀部署**（Canary Deployment），以及結合功能旗標（Feature Flags）的漸進式釋出等【34†L145-L153】。使用者可在管道階段中輕鬆切換部署類型，例如直接指定啟用金絲雀或藍綠模式。Harness 也內建與 Kubernetes 部署相關的策略，例如可以指定自動回滾條件、滾動重啟（`patchManifest` with `LAST_ROLLOUT=now()`）等，以最低干擾完成升級【34†L153-L161】【29†L1549-L1557】。

在藍綠與滾動部署中，Harness 支援彈性流量切換（例如在 AWS ECS 上的藍綠更新時可自動配置流量規則），同時提供用戶控制，例如在部署過程中插入配置擴縮策略而不影響現有容器【29†L1539-L1547】【29†L1551-L1556】。使用功能旗標可在不重新部署的情況下完成部分釋出和回滾；Harness 的 Feature Flag 功能允許在運行時動態開啟/關閉功能，並可與部署管道集成以實現無縫的漸進式交付。

## 可觀察性、監控與回滾機制

Harness 平臺內建豐富的 **觀察性** 與驗證功能。持續交付中的 **Continuous Verification (CV)** 模組會從 APM、日誌和監控工具收集應用程式指標，並應用機器學習檢測部署後的異常。如果發現風險，Harness 可自動觸發回滾以在問題擴大前還原版本【34†L153-L157】。此外，平臺提供實時部署 **儀表板**，顯示關鍵指標（如部署頻率、交付前置時間、失敗率等 DORA 指標）【34†L175-L179】；使用者也可建立自訂面板並整合 Slack、Microsoft Teams、電子郵件等通知。Harness 可以追蹤每次部署的日誌與輸出，以便事後分析與調試【31†L193-L196】【34†L175-L179】。

在部署失敗時，Harness 能自動回滾到前一穩定版本，或依配置停留在故障狀態待人為介入。這種「智能驗證+自動回滾」機制，能大幅降低生產事故的風險【34†L153-L157】【10†L218-L223】。同時，Harness 支援在管道中插入自動化檢查與人工核准節點，例如與 Jira/ServiceNow 的審批流程整合，確保變更在合規要求下進行【41†L7-L14】【34†L153-L161】。

## 安全、合規、RBAC、機密管理與審計

Harness 平臺在安全與合規方面具備全面設計。**角色與權限控制 (RBAC)** 允許管理者定義用戶群組及其對組織、專案與管道的操作權限【38†L106-L113】【34†L168-L173】。平臺可與單一登入 (SSO) 系統整合，用戶行為會被完整審計並記錄日誌【34†L168-L173】。對於敏感資訊，Harness 內建了 **Secrets 管理** 功能，可安全加密儲存密碼、金鑰等憑證；同時，也支援主流雲端秘密管理器，如 AWS Secrets Manager、HashiCorp Vault、Azure Key Vault、Google Cloud KMS 等【38†L115-L123】，方便使用這些服務儲存與參考現有機密。平台還提供 OPA（Open Policy Agent）為基礎的政策機制，可實施組織合規規則，如禁止在特定環境部署未核准的映像等【34†L153-L161】。

例如，Harness 的審計日誌會記錄誰在何時對哪條管道做了哪些設定，並能生成證據供安全稽核【34†L168-L173】。企業版中可建立組織級的準則集 (Policy Sets)，在部署前自動檢驗 Terraform 或 Kubernetes 配置是否符合政策，違規時即終止流程【40†L37-L45】【41†L7-L14】。Harness 的安全與合規功能使得大型組織能在加速部署的同時，保持嚴格的治理與監控。

## 可擴展性、效能與高可用設計

Harness 採用 SaaS 架構，核心平臺（Manager）由服務商管理；客戶只需在自己的網路或雲中部署 Delegate 代理即可擴展執行能力。單個 Delegate 副本通常能處理約 10 個併發部署/構建流程【20†L242-L250】，可根據負載彈性增設多副本。例如，官方指南建議每增加約 50 個 Kubernetes 節點，Delegate 配置增加 0.5 vCPU 和 2 GB 記憶體以維持效能【20†L256-L264】。Harness 還支援 Kubernetes 原生部署 Delegate，並可使用水平自動擴充 (HPA) 機制管理副本數量【20†L242-L250】。多副本 Delegate 之間由 Harness Manager 分配任務，若某個 Delegate 不可用，系統可自動將任務移轉至其他可用副本【20†L327-L334】。

平台本身採多租戶設計，各租戶資料在後端隔離並加密儲存【5†L19-L22】。Harness SaaS 平臺具備高可用架構，以確保在任一個多雲環境中持續提供服務。客戶使用自建版時，也可透過部署多個管理節點與資料庫複本來實現 HA 目標。整體來說，Harness 的架構能支援大型企業的高頻部署需求與地理分散部署。

## 成本模型與授權選項

Harness 採用開放核心與分階層收費模式。2024 年起，Harness 提供**免費的開源版**（Harness Open Source），可下載安裝並使用包括代碼託管、CI、CD、制品庫等功能，採用 Apache 2.0 許可證【16†L206-L214】。此外，Harness 還有免費的社群版（Community Edition），採源代碼可見的 PolyForm Shield 許可證釋出【36†L251-L259】。企業版（Enterprise Edition）則包含進階功能（如 AI 驗證、支援 SLA、專業支援等），需依模組與規模採購；Harness 官方建議聯繫銷售以瞭解定價細節【36†L251-L259】【16†L206-L214】。公開資訊顯示，Harness 的企業方案通常採用「每開發者/每模組」計費，整體成本會隨團隊規模與功能需求增加（例如每位開發者每月可能數十美元起）。若團隊僅需部分功能，也可使用單模組組合方案或免費層級。若沒有公布具體數字，建議企業在評估時與 Harness 銷售顧問確認方案與費用。

## 與主要雲端與工具的整合

Harness 提供豐富的**原生整合**，涵蓋公有雲、容器平台、基礎建設即程式碼 (IaC)、Git 服務等。對於雲端供應商，Harness 支援 AWS（EKS、ECS、Lambda、CloudFormation、AMI/Auto Scaling 等）、Google Cloud（GKE、Cloud Run、Cloud Functions 等）及 Azure（AKS、App Services、Function、ARM Templates 等）等服務【39†L11-L19】【38†L115-L123】。在容器與編排方面，除了支援 Kubernetes 原生部署外，也支援 Helm Chart、Kustomize、OCIL 等多種包管方式【39†L163-L172】。IaC 部分，Harness 的「Provisioners」可執行 Terraform、Terragrunt、Azure ARM 模板與 Blueprint 等，並與 Terraform Cloud/Enterprise 整合，以便執行預寫的基礎設施計畫【40†L29-L33】。在 GitOps 模式下，Harness 可與 ArgoCD 整合，將 Git 變更自動同步到 Kubernetes 環境【34†L161-L166】。

與版本控制相關，Harness 支援 GitHub、GitLab、Bitbucket、Azure Repos 及 AWS CodeCommit 等主流 Git 平臺，並透過「Harness Git Experience」實現管道定義儲存在 Git (如 `.harness` 目錄) 的能力【31†L142-L150】【39†L155-L163】。此外，Harness 也提供內建的 Git 託管服務（Harness Gitness），並可進行一鍵遷移，以便團隊選擇自行管理或使用 Harness 提供的整合開發平臺【16†L189-L198】。其他常見工具整合還包括：與制品庫整合（Docker Hub、ECR、Nexus、Artifactory 等）、第三方認證（OAuth、SSO）、通知系統（Slack、Teams、Email）、監控與 APM（Datadog、New Relic、Splunk 等）以及審批管理（Jira、ServiceNow 等）【41†L7-L14】【38†L115-L123】。

## 競爭者比較

以下表格將 Harness 與 GitLab CI/CD、Argo CD、Spinnaker、Jenkins X 等常見競品做比較。各工具特點如下（來源：各平臺文件與業界報導）：

| 功能/特性            | **Harness**                                        | **GitLab CI/CD**                                   | **Argo CD**                   | **Spinnaker**             | **Jenkins X**                   |
|--------------------|-------------------------------------------------|-------------------------------------------------|-----------------------------|------------------------|-------------------------------|
| **性質**           | SaaS 或自建商用平臺；開放核心，企業版收費           | 整合式 DevOps 平臺 (源控制+CI/CD)；可自建或 SaaS      | 開源 GitOps 工具（K8s 專用）；可與 Argo Rollouts 結合 | 開源多雲 CD 工具，原 Netflix；自建 | 開源 K8s 原生 CI/CD (基於 Jenkins/Tekton)  |
| **CI 功能**        | 內建 CI；容器化管道；支援並行構建；有免費 SaaS 架構     | 內建 CI； Runner 架構；Docker 支援；高效緩存   | 無內建 CI；需搭配其他 CI (GitHub Actions, Jenkins, 等) | 部分支援，需要外部 CI 配合 | 內建 CI；多分支流水線；PR 預覽環境 |
| **CD / GitOps**    | 支援 CD（K8s/VM/Serverless）；內建金絲雀/藍綠；GitOps 模式 | 支援 CD，K8s 及 Serverless；有 Auto DevOps 功能；基本 GitOps | 原生 GitOps：宣告式同步 K8s；支援 Helm/Kustomize    | 強大多雲 CD：EKS/GKE/AKS/VM 等；內建 Canary (Kayenta) | 支援 GitOps 及自動預覽環境；多雲偏向 K8s    |
| **部署策略**      | 滾動、藍綠、金絲雀、功能旗標；自動驗證與回滾          | 滾動、藍綠 (Runner 支援)；基本環境隔離       | 原生支援滾動 (K8s 同步)；金絲雀需外部工具         | 滾動、藍綠、金絲雀 (Kayenta)；多雲       | 滾動、藍綠；由 Lighthouse/Kaniko 等實現      |
| **觀察與回滾**    | 內建 ML 驗證 (Continuous Verification)；自動回滾    | 基本 Pipeline 狀態；需外掛 APM/監控          | 只同步檢查；無自動回滾                    | 支援 Kayenta 金絲雀分析；手動/自動回滾  | 需配置 Argo Rollouts 或自定義腳本     |
| **安全與合規**     | 細粒度 RBAC；與 Vault/AWS/Azure KMS 整合；審計與政策機制 | RBAC (EE版)；SAST/DAST 內建；審計日誌可查       | 核心功能單純；可搭配外部 RBAC 工具       | RBAC；基本審計；需外部工具增強安全 (如 Keel) | RBAC 可依雲環境設置；需自行管理審計       |
| **整合工具**       | Git (多家)、制品註冊表、Terraform、Helm、通知、監控等【38†L115-L123】【39†L155-L163】 | GitLab 自家倉庫；支援多雲 (EKS/GKE/AKS)；CI/CD 一條龍 | 只支援 Kubernetes (Helm/Kustomize)              | 多雲原生 (EKS/GKE/AKS/VM)；可執行 Terraform  | K8s 原生；內建環境管理；與 Tekton、Prow 整合    |
| **授權與成本**     | 開放核心 (社群版/開源免費) + 企業收費；需聯繫報價            | 開源 CE；付費 EE (高級功能)；雲端版按用戶訂閱      | 完全開源免費 (Akutiy enterprise 付費)       | 開源免費；需自建資源與維運成本         | 開源免費；社群版；需自建與維運           |
| **適用場景**      | 需要企業級 CI/CD 平臺，重視管道可視化與驗證自動化        | 尋求「一體化」DevOps 平臺；已有 GitLab 生態     | 只聚焦 Kubernetes GitOps；偏向純 K8s 團隊 | 多雲架構大規模部署；擅長複雜多帳號環境 | 雲原生+微服務團隊；需動態預覽環境與快速迭代     |

以上比較突顯出 Harness 的定位：作為集成 CI/CD 與 GitOps 的全功能商用平臺，其優勢在於強大的自動化驗證與企業治理功能，但需要付費和較高的配置成本。GitLab 提供開源加企業版，適合想要「全包式」解決方案的團隊；Argo CD 則是純開源的 Kubernetes GitOps 工具，只能用於 K8s 部署；Spinnaker 可應對多雲部署，但需大量自建和維護；Jenkins X 強調雲原生與 CI/CD 自動化，但目前社群規模小於 Jenkins 傳統版。

## 實際案例與效能指標

多個大型企業已採用 Harness 平臺並取得顯著成效。例如，美國聯合航空（United Airlines）使用 Harness 取代 Jenkins 進行 CI/CD，結果 **部署時間從原本的 22 分鐘縮短到 5 分鐘**，部署速度提高約 75%【52†L168-L172】；而通過並行執行管道，其整體效率也提升 75%，能在短短 50 秒內產生 10 條部署管道【54†L269-L272】，而過去執行相同工作量需要「天或週」時間。這使得 United 的開發團隊能快速響應市場需求，同時自動化安全與合規流程，提高整體運營效率【54†L269-L272】【52†L168-L172】。其他客戶案例還包括 Citi、NAB 等金融機構均報告了顯著的部署頻率與可靠性改善。在 Google Cloud 平臺上的一項案例顯示，採用 Harness 後可將開發時間減少約 50%，開發效率提高 75%【49†L8-L11】。

## 採用最佳實踐與遷移計畫

對於有意導入 Harness 的企業，建議採取階段式遷移策略：首先在非生產環境或新項目上試點，驗證管道設計與自動化流程。在此階段，可將現有 Jenkins 或其他 CI/CD 工具的管道遷移至 Harness，利用其導入工具與 YAML 定義簡化過程。接著，與安全、合規、業務團隊協商，建立 Harness 的角色權限與審批流程，以及機密管理政策。重要風險包括：員工對新平臺不熟悉、遷移過程中中斷服務，以及與現有工具整合的兼容性問題。Mitigation 措施包含舉辦培訓（Harness 官方有認證課程）、從小規模專案開始推行、保持現有環境並行運行作業，以及與 Harness 支援密切合作解決技術問題。

**遷移階段示例**：  
1. **規劃與評估**：列出目前 CI/CD 流程的需求與痛點，與 Harness 專家討論對應解決方案。  
2. **PoC 開發**：選擇一個或數個低風險服務，在 Harness 中建立管道，測試部署策略與驗證配置。  
3. **並行驗證**：與現有系統並行運行，驗證 Harness 的部署結果，並進行性能與安全測試。  
4. **全量切換**：逐步將更多項目移至 Harness，廢棄舊工具。可分組過渡以降低風險。  
5. **優化與擴展**：定期審視 DORA 指標與成本，優化管道效能，並擴展到其他團隊或地區。  
6. **治理與維運**：設定定期審計與回顧，確保政策符合最新合規要求；可考慮引入 DevOps 工程師保持平臺健康。

## 缺陷、限制與未來趨勢

即便功能強大，Harness 也有一些限制與挑戰。使用者反映其複雜度較高，小型團隊需要花費較長學習時間【46†L100-L107】；對於只需單一模組（如僅 CI 或 CD）的場景，Harness 整體套件可能顯得過大且昂貴【46†L84-L93】。目前對於多租戶（多組織）場景的細節設定可能不夠靈活，某些自訂工具或新興平台整合尚未涵蓋，需自建擴展。未來趨勢方面，Harness 正朝向更深的 AI 自動化（自動生成管道、智慧測試選擇、變更風險預測）、以及更完善的多雲/混合雲支援發展。此外，全球 DevOps 產業正強調「製品化環境」（Preview Environments）與內部開發人員入口（IDP），Harness 可能會在內部產品門戶（Internal Developer Portal）等領域進一步擴充。

## 參考資料

- Harness 官方文件與部落格【18†L138-L144】【31†L174-L183】【34†L145-L153】【38†L115-L123】等。  
- Harness 案例研究：United Airlines【52†L168-L172】【54†L269-L272】、Build.com、Citi、NAB 等。  
- 產業比較與報導，如 Harness 官方部落格【44†L155-L163】、Bunnyshell 評比【46†L125-L133】等。  
- 開源/第三方資訊：Harness GitHub 許可證【36†L251-L259】、業界新聞【23†L129-L137】。