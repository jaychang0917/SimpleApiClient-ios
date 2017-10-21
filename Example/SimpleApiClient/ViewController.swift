import UIKit
import SimpleApiClient

class ViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    
    GithubClient.shared.getUsers(query: "foo")
      .cancel(when: self.rx.deallocated)
      .observe(
        onStart: { print("show loading") },
        onEnd: { print("hide loading") },
        onSuccess: { print("sucess: \($0)") },
        onError: { print("error: \($0)") }
      )
  }
}
