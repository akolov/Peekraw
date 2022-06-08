//
//  Subviews.swift
//  Peekraw
//
//  Created by Alexander Kolov on 2022-06-08.
//

#if canImport(UIKit)
import UIKit

@resultBuilder
public struct SubviewsBuilder {
  // swiftlint:disable:previous convenience_type

  public static func buildBlock(_ content: UIView...) -> [UIView] {
    return content
  }

}

extension UIView {

  /**
    Defines the view hierachy for the view.

    Esentially, this is just a shortcut to `addSubview`
    and 'translatesAutoresizingMaskIntoConstraints = false'

    ```
    class MyView: UIView {

      let email = UITextField()
      let password = UITextField()
      let login = UIButton()

      convenience init() {
        self.init(frame: CGRect.zero)

        subviews(
          email,
          password,
          login
        )
        ...

      }
    }

    ```

    - Returns: Itself to enable nested layouts.
  */
  @discardableResult
  public func subviews(_ subViews: UIView...) -> UIView {
    subviews(subViews)
  }

  /**
    Defines the view hierachy for the view.

    Esentially, this is just a shortcut to `addSubview`
    and 'translatesAutoresizingMaskIntoConstraints = false'

    ```
    class MyView: UIView {

      let email = UITextField()
      let password = UITextField()
      let login = UIButton()

      convenience init() {
      self.init(frame: CGRect.zero)

        subviews {
          email
          password
          login
        }
        ...

      }
    }

    ```

    - Returns: Itself to enable nested layouts.
  */
  @discardableResult
  public func subviews(@SubviewsBuilder content: () -> [UIView]) -> UIView {
    subviews(content())
  }

  /**
    Defines the view hierachy for the view.

    Esentially, this is just a shortcut to `addSubview`
    and 'translatesAutoresizingMaskIntoConstraints = false'

    ```
    class MyView: UIView {

      let email = UITextField()
      let password = UITextField()
      let login = UIButton()

      convenience init() {
        self.init(frame: CGRect.zero)

        subviews {
          email
          password
          login
        }
        ...

      }
    }

    ```

    - Returns: Itself to enable nested layouts.
  */
  @discardableResult
  public func subviews(@SubviewsBuilder content: () -> UIView) -> UIView {
    let subview = content()
    subviews(subview)
    return self
  }

  /**
    Defines the view hierachy for the view.

    Esentially, this is just a shortcut to `addSubview`
    and 'translatesAutoresizingMaskIntoConstraints = false'

    ```
    class MyView: UIView {

      let email = UITextField()
      let password = UITextField()
      let login = UIButton()

      convenience init() {
      self.init(frame: CGRect.zero)

        subviews(
          email,
          password,
          login
        )
        ...

      }
    }

    ```

    - Returns: Itself to enable nested layouts.
  */
  @discardableResult
  @objc
  public func subviews(_ subViews: [UIView]) -> UIView {
    for sv in subViews {
      addSubview(sv)
      sv.translatesAutoresizingMaskIntoConstraints = false
    }
    return self
  }

}

extension UITableViewCell {

  /**
    Defines the view hierachy for the view.

    Esentially, this is just a shortcut to `contentView.addSubview`
    and 'translatesAutoresizingMaskIntoConstraints = false'

    ```
    class NotificationCell: UITableViewCell {

      var avatar = UIImageView()
      var name = UILabel()
      var followButton = UIButton()

      required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
      override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
      super.init(style: style, reuseIdentifier: reuseIdentifier) {

        subviews(
          avatar,
          name,
          followButton
        )
        ...

      }
    }
    ```

    - Returns: Itself to enable nested layouts.
  */
  @discardableResult
  public override func subviews(_ subViews: [UIView]) -> UIView {
    // swiftlint:disable:previous override_in_extension
    contentView.subviews(subViews)
  }

}

extension UICollectionViewCell {

  /**
    Defines the view hierachy for the view.

    Esentially, this is just a shortcut to `contentView.addSubview`
    and 'translatesAutoresizingMaskIntoConstraints = false'

    ```
    class PhotoCollectionViewCell: UICollectionViewCell {

      var avatar = UIImageView()
      var name = UILabel()
      var followButton = UIButton()

      required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
      override init(frame: CGRect) {
        super.init(frame: frame)

        subviews(
          avatar,
          name,
          followButton
        )
        ...

      }
    }
    ```

    - Returns: Itself to enable nested layouts.
  */
  @discardableResult
  public override func subviews(_ subViews: [UIView]) -> UIView {
    // swiftlint:disable:previous override_in_extension
    contentView.subviews(subViews)
  }

}

extension UIStackView {

  @discardableResult
  public func arrangedSubviews(@SubviewsBuilder content: () -> [UIView]) -> UIView {
    arrangedSubviews(content())
  }

  @discardableResult
  public func arrangedSubviews(@SubviewsBuilder content: () -> UIView) -> UIView {
    arrangedSubviews([content()])
  }

  @discardableResult
  private func arrangedSubviews(_ subViews: UIView...) -> UIView {
    arrangedSubviews(subViews)
  }

  @discardableResult
  public func arrangedSubviews(_ subViews: [UIView]) -> UIView {
    subViews.forEach { addArrangedSubview($0) }
    return self
  }

}

#endif
