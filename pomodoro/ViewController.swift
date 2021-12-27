//
//  ViewController.swift
//  pomodoro
//
//  Created by 양혜지 on 2021/12/16.
//


import UIKit
import AudioToolbox


// 열거형
enum TimerStatus {
    case start
    case pause
    case end
}

// gcd 작업을 병렬적으로 적용하기 위해 애플이 제공
// 쓰레드 관리: 태스크들이 만든 큐를 만들고 큐를 던져버리면 Gcd가 관리해준다.


class ViewController: UIViewController {

   
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var toggleButton: UIButton!
    
    @IBOutlet weak var ImageView: UIImageView!
    
    var duration = 60
    var timerStatus: TimerStatus = .end
    var timer: DispatchSourceTimer?
    var currentSeconds = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureToggleButton()
        // Do any additional setup after loading the view.
    }

    func setTimerInfoViewVisable(isHidden: Bool){
        self.timeLabel.isHidden = isHidden
        self.progressView.isHidden = isHidden
    }
    
    func configureToggleButton() {
        self.toggleButton.setTitle("시작", for: .normal)
        self.toggleButton.setTitle("일시정지", for: .selected)
    }
    
    func startTimer() {
        // 메인쓰레드 ios에서 오직 한개만 존재한다. 인터페이스 관련 코드는 메인스레드에서 구현되어야한다.
        // 타이머가 돌 때 마다 ui가 바꿔야되서 queue를 메인쓰레드로 두었다.
        if self.timer == nil {
            self.timer = DispatchSource.makeTimerSource(flags: [], queue: .main)
            self.timer?.schedule(deadline: .now(), repeating: 1)
            // deadline: 3초 이후 시간 .now()+3
            self.timer?.setEventHandler(handler: { [weak self] in
                guard let self = self else { return }
                self.currentSeconds -= 1
                let hour = self.currentSeconds / 3600
                let minutes = (self.currentSeconds % 3600) / 60
                let seconds = (self.currentSeconds % 3600) % 60
                self.timeLabel.text = String(format: "%02d:%02d:%02d", hour, minutes, seconds)
                // 프로그래스바
                self.progressView.progress = Float(self.currentSeconds) / Float(self.duration)
                //debugPrint(self.progressView.progress)
                
               // debugPrint(self.currentSeconds)
                
                // CGAffineTransform  뷰의 프레임을 계산하지 않고 cgaffinetransform을 사용해 2D 그래픽을 구현
                UIView.animate(withDuration: 0.5, delay: 0, animations: {self.ImageView.transform = CGAffineTransform(rotationAngle: .pi)})
                UIView.animate(withDuration: 0.5, delay: 0.5, animations: {self.ImageView.transform = CGAffineTransform(rotationAngle: .pi * 2)})
                
                if self.currentSeconds ?? 0 <= 0 {
                    // 타이머가 종료
                    self.stopTimer()
                    AudioServicesPlaySystemSound(1005)
                }
            })
            
            self.timer?.resume()
        }
    }
    
    
    // 일시정지 상태 suspense를 사용하고 바로 nil을 대입하면 런타임 에러가 발생한다.
    // 그러므로 일시정지 상태에서 타이머를 중지하고 nil을 대입할려면 그전에 resume()메서드를 호출해야한다.
    func stopTimer() {
        if self.timerStatus == .pause {
            self.timer?.resume()
        }
        self.timerStatus = .end
        self.cancelButton.isEnabled = false
        // hiddden을 사용하면 뚝뚝 끊겨서 스무스 하게 애니메이션 처럼 사라지게 하기
        UIView.animate(withDuration: 0.5, animations: {
            self.timeLabel.alpha = 0
            self.progressView.alpha = 0
            self.datePicker.alpha = 1
            self.ImageView.transform = .identity // 이미지뷰가 원상태로 복귀
        })
        self.toggleButton.isSelected = false
        self.timer?.cancel()
        self.timer = nil
    }
    
    @IBAction func tapCancleButton(_ sender: Any) {
        switch self.timerStatus{

        case .start, .pause :
          
            self.stopTimer()
            
            
        default:
            break
        }
    }
    
    @IBAction func tapToggleButton(_ sender: Any) {
        self.duration = Int(self.datePicker.countDownDuration)
        switch self.timerStatus {
        case .end :
            self.currentSeconds = self.duration
            self.timerStatus = .start
            UIView.animate(withDuration: 0.5, animations: {
                self.timeLabel.alpha = 1
                self.progressView.alpha = 1
                self.datePicker.alpha = 0
            })
//            self.setTimerInfoViewVisable(isHidden: false)
//            self.datePicker.isHidden = true
            self.toggleButton.isSelected = true
            self.cancelButton.isEnabled = true
            self.startTimer()
            
        case .start:
            self.timerStatus = .pause
            self.toggleButton.isSelected = false
            self.timer?.suspend()
            
        case .pause:
            self.timerStatus = .start
            self.toggleButton.isSelected = true
            self.timer?.resume()
            
        default:
            break
        }
        
    }
}

